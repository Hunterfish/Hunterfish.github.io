{%
  set boot_scripts = [
    'src/bootstrap.js'
  ]
%}

{% for bs in boot_scripts %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ bs }}?v={{ theme.version }}"></script>
{% endfor %}

{% if theme.baidu_push %}
<script>
(function(){
    var bp = document.createElement('script');
    var curProtocol = window.location.protocol.split(':')[0];
    if (curProtocol === 'https') {
        bp.src = 'https://zz.bdstatic.com/linksubmit/push.js';
    }
    else {
        bp.src = 'http://push.zhanzhang.baidu.com/push.js';
    }
    var s = document.getElementsByTagName("script")[0];
    s.parentNode.insertBefore(bp, s);
})();
</script>
{% endif %}

作者：小矮人Ethan
链接：https://www.jianshu.com/p/8c0707ce5da4
來源：简书
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
