(function(){
  try {
    // 年份
    var ySpan = document.querySelector('footer [data-year]');
    if (ySpan) ySpan.textContent = new Date().getFullYear();
    // 尝试读取构建版本（由 build_revision 生成器写入 /build-revision.json）
    fetch('/build-revision.json',{cache:'no-store'}).then(function(r){
      if(!r.ok) return; return r.json();
    }).then(function(data){
      if(!data) return;
      var revEl = document.getElementById('build-rev');
      var timeEl = document.getElementById('build-time');
      var short = data.short || data.hash || '';
      if (revEl) {
        // 若你希望跳转到仓库对应提交，可在页面提前定义 window.REPO_URL，如 https://github.com/user/repo
        if (window.REPO_URL && short) {
          revEl.innerHTML = '<a href="'+window.REPO_URL.replace(/\/$/,'')+'/commit/'+data.hash+'" target="_blank" rel="noopener" title="构建版本">'+short+'</a>';
        } else {
          revEl.textContent = short;
        }
      }
      if (timeEl && data.date) {
        // 格式化日期（本地时区，精简）
        try {
          var dt = new Date(data.date);
          var pad = n=>n.toString().padStart(2,'0');
          var formatted = dt.getFullYear()+'-'+pad(dt.getMonth()+1)+'-'+pad(dt.getDate())+' '+pad(dt.getHours())+':'+pad(dt.getMinutes());
          timeEl.textContent = formatted;
        } catch(e) {}
      }
    }).catch(function(){});
  } catch(e) {}
})();
