#!/usr/bin/env bash
set -euo pipefail
# Twikoo Mongo 副本集重置与初始化脚本
# 用途：当出现 ReplicaSetNoPrimary / 未创建 oplog.rs / 初始化失败时快速重建
# 注意：默认不清空数据；如需强制清空，追加 --purge 或设置 PURGE=1
# 使用：
#   bash ops/twikoo-reset.sh            # 仅重启并尝试补 init
#   bash ops/twikoo-reset.sh --purge    # 停止并删除 ./data/twikoo-db 下数据后重建
#   PURGE=1 bash ops/twikoo-reset.sh    # 等效 --purge

COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.yml}
DB_VOLUME_DIR=${TWIKOO_DB_DIR:-./data/twikoo-db}
PURGE_FLAG=${PURGE:-0}
if [[ ${1:-} == "--purge" ]]; then PURGE_FLAG=1; fi

log(){ echo -e "[twikoo-reset] $*"; }

if [[ ! -f ${COMPOSE_FILE} ]]; then
  log "未找到 ${COMPOSE_FILE}，请在项目根目录执行"; exit 1; fi

log "STEP 1: 停止相关容器"
docker compose -f ${COMPOSE_FILE} rm -sf twikoo twikoo-index-init twikoo-rs-init || true
# 不直接 down 全部，避免误停其它服务；只移除相关容器

if [[ ${PURGE_FLAG} == 1 ]]; then
  log "STEP 2: 清空 Mongo 数据目录 ${DB_VOLUME_DIR} (不可逆)"
  rm -rf "${DB_VOLUME_DIR}" || true
fi
mkdir -p "${DB_VOLUME_DIR}"

log "STEP 3: 启动 Mongo"
docker compose -f ${COMPOSE_FILE} up -d twikoo-db

log "STEP 4: 等待 Mongo 健康"
for i in {1..30}; do
  if docker exec twikoo-db mongosh --quiet --eval 'db.adminCommand("ping").ok' >/dev/null 2>&1; then
    log "Mongo 可用"; break; fi; sleep 2
done

log "STEP 5: 初始化副本集（若未初始化）"
set +e
RS_STATUS=$(docker exec twikoo-db mongosh --quiet --eval 'try{rs.status().ok}catch(e){0}')
set -e
if [[ "${RS_STATUS}" != "1" ]]; then
  docker exec twikoo-db mongosh --quiet --eval 'rs.initiate({_id:"rs0", members:[{_id:0, host:"twikoo-db:27017"}]})'
  sleep 2
fi

log "STEP 6: 打印副本集成员状态"
docker exec twikoo-db mongosh --quiet --eval 'rs.status().members.forEach(m=>print(m.name, m.stateStr))'

log "STEP 7: 创建索引 (幂等)"
docker exec twikoo-db mongosh twikoo --quiet --eval '
  function ensureIndex(coll, spec, opts){
    // 确保集合存在（createIndex 本身可建集合，但 getIndexes 在集合缺失时会抛 ns does not exist）
    try {
      if (!db.getCollectionNames().includes(coll)) {
        db.createCollection(coll);
        print("createCollection:"+coll);
      }
    } catch(e) { print("warn:createCollection:"+coll+" -> "+e); }

    let existing = [];
    try { existing = db.getCollection(coll).getIndexes().map(i=>i.name); } catch(e){ existing=[]; }
    if (existing.indexOf(opts.name) === -1) {
      try {
        db.getCollection(coll).createIndex(spec, opts);
        print("created:"+coll+"."+opts.name);
      } catch(e){ print("error:createIndex:"+coll+"."+opts.name+" -> "+e); }
    } else {
      print("exists:"+coll+"."+opts.name);
    }
  }
  ensureIndex("comment", { url:1 }, { name:"url_1" });
  ensureIndex("comment", { created:-1 }, { name:"created_-1" });
  ensureIndex("comment", { rid:1 }, { name:"rid_1" });
  ensureIndex("comment", { mailMd5:1 }, { name:"mailMd5_1" });
  ensureIndex("counter", { url:1 }, { name:"url_counter_1" });
'

log "STEP 8: 启动 Twikoo 服务"
docker compose -f ${COMPOSE_FILE} up -d twikoo
sleep 2

log "STEP 9: 简单连通性测试"
HTTP_CODE=$(curl -m 5 -s -o /dev/null -w '%{http_code}' ${TWIKOO_PUBLIC_URL:-http://localhost/twikoo/} || true)
log "Twikoo API HTTP 状态: ${HTTP_CODE} (非 200 也可能因空 POST 逻辑)"

log "完成。如果页面仍 30s 超时，请贴 twikoo 容器日志。"