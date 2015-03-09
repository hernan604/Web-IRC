Class('AppChatPluginYoutube', {
    has     : {
        regex : {
            is   : "rw", 
            init : (function () {
                return /https:\/\/www.youtube.com\/watch\?v=([a-zA-Z0-9_-]+)([^ ]*)/gi ;
            })() 
        }
    },
    methods : {
        handles : function ( msg ) {
            return this.regex.test( msg );
        },
        process : function ( msg ) {
            if ( matches = this.regex.exec( msg ) ) {
                var new_content = '<iframe id="video" width="420" height="315" src="//www.youtube.com/embed/'+matches[1]+'?rel=0" frameborder="0" allowfullscreen></iframe>';
                msg = msg.replace( matches[0], matches[0] + ': ' + new_content );
            }
            return msg;
        }
    }
})
