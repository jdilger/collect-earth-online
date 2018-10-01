<#include "header.ftl">
<#include "navbar.ftl">
<#include "announcements.ftl">
<#include "start-content.ftl">
<div id="home"></div>
<script type="text/javascript" src="${root}/js/bundle.js"></script>
<script type="text/javascript">
 window.onload = function () {
     renderPage("home",
                {
                    documentRoot: "${root}",
                    userId:       "${userid}",
                    username:     "${username}"
                }
     );
 };
</script>
<#include "end-content.ftl">
<#include "footer.ftl">
