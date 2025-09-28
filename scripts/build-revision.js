/*
 * 生成 build-revision.json 文件，供前端 footer-year.js 获取并显示版本号
 * 写入 fields:
 *   hash  - 完整 git 提交哈希
 *   short - 短哈希
 *   date  - 构建时间 ISO 字符串
 */
const { execSync } = require('child_process');
const fs = require('fs');

hexo.extend.filter.register('after_generate', function(){
  function safe(cmd){ try { return execSync(cmd,{stdio:['ignore','pipe','ignore']}).toString().trim(); } catch(e){ return ''; } }
  const hash = safe('git rev-parse HEAD');
  const short = safe('git rev-parse --short HEAD');
  const data = { hash, short, date: new Date().toISOString() };
  const out = hexo.public_dir + 'build-revision.json';
  try {
    fs.writeFileSync(out, JSON.stringify(data, null, 2));
    hexo.log.info('[build-revision] generated', data);
  } catch(e){
    hexo.log.warn('[build-revision] write failed', e);
  }
});
