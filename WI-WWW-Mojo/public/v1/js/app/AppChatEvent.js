Class('AppChatEvent', {
    does : [],
    has : {
        app  : { is : "rw" },
        deps : {
            is  : "rw",
            init: (function(){return [
              //jloader.load('AppChatPluginYoutube')
            ]})(),
          //init: (function() {
          //    jloader.load('./js/jquery.min.js', { eval : false })
          //    return [
          //        jloader.load('ClassTest2'),
          //        jloader.load('ClassTest1')
          //    ]
          //})()
        },
        lib_loader  : { is  : "rw" },
        instances   : {
            is    : "rw", 
            init  : (function(){ return [];})()
        },
        channel     : { is  : 'rw' },
        ws          : { is  : 'rw' },
        log         : { is  : 'rw' },
        plugins     : { is  : 'rw' },
        tpl_join_part: {
            is : 'rw',
            init : (function () {
                var tpl = "\
                <li class='row msg'>\
                <div class='col-sm-1'><div class='row photo userpic'></div></div>\
                <div class='col-sm-11'><div class='row'><span class='username'>{{nick}}</span><span class='date'>{{hms}}</span></div><div class='row'><span class='notice'>{{action}}</span></div></div>\
                <li>\
                "; 
                return tpl;
            })()
        },
    },
    methods : {
        load_libs : function () {
            var _this = this;
            this.when_done = _this.carregou_libs;
        },
        init : function () {
            var _this = this;
            for (var i=0, myclass; myclass = this.deps[i]; i++) {
                var myinstance = new myclass({
                    app : _this
                });
                ( myinstance.init )
                    ? myinstance.init()
                    : undefined
                    ;
            }
            this.setLog( $( '#log[chan='+_this.channel+']' ) );

            jloader.load('AppChatPluginYoutube');
            this.setPlugins([
                new AppChatPluginYoutube()
            ]);

            this.init_ws();
        },
        init_ws : function () {
            var _this = this;
            $('#msg').focus();
            _this.ws.onopen = function () {
//              _this.log('Connection opened');
            };
            _this.ws.onmessage = function (msg) {
                console.log(msg);
              var res = JSON.parse(msg.data);
                   if ( res.action == 'message' )   { _this.msg(res)  }
              else if ( res.action == 'join' )  { _this.join(res) }
              else if ( res.action == 'part' )  { _this.part(res) }
            };

            $('#msg').keydown(function (e) {
              _this.animate_keypress(e);
              if (e.keyCode == 13 && $('#msg').val()) {
                  _this.submit();
              }
            });
            $('#msg').keyup(function (e) {
                _this.animate_keyup(e);
            })

            $('.btn.send').click( function ( ev ) {
                _this.submit();
            } )
        },
        submit : function () {
            var _this = this;
            var msg = $('#msg').val();
            var data = JSON.stringify({ source : 'web', action: 'msg', msg : msg });
            _this.ws.send( data );
            setTimeout( function () { 
                $('#msg').val('');
            } , 10 )
        },
        animate_keypress : function ( ev  ) {
            $( ev.currentTarget )
                .removeClass('keyup')
                .addClass('keydown')
        },
        animate_keyup : function ( ev  ) {
            $( ev.currentTarget )
                .removeClass('keydown')
                .addClass('keyup')
                ;
        },
        msg : function ( res ) {
            for ( var i = 0, plugin; plugin = this.plugins[ i ] ; i++ ) {
                res.text = plugin.process( res.text );
            }

            var msg_markup = $('<li/>')
                .addClass('row msg')

            var msg_col_left = $('<div/>').addClass('col-sm-1')
                .appendTo( msg_markup )

            var msg_col_right = $('<div/>').addClass('col-sm-11')
                .appendTo( msg_markup )
            var row_1 = $( '<div/>' ).addClass('row')
                .appendTo( msg_col_right )
            var row_2 = $( '<div/>' ).addClass('row')
                .appendTo( msg_col_right )

            var username = $('<span/>')
                .html( res.nick )
                .addClass('username')
                .appendTo( row_1 )

            var date = $('<span/>') 
                .addClass('date')
                .html( res.hms )
                .appendTo( row_1 )

            var text = $('<span/>').html( res.text )
                .appendTo( row_2 )

            var photo_container = $('<div>')
                .addClass( 'row photo userpic' )
                .appendTo( msg_col_left )

//          var photo = $('<img>')
//              .addClass('userpic')
//              .appendTo( photo_container )
//              ;

            var msg = $('<li/>')
                .append( msg_markup )
//              .append(username)
//              .append( $('<span/>').html( res.text ) )
                ;

            msg_markup
                .appendTo(log)
            this.log.scrollTop(this.log[0].scrollHeight);
        },
        join : function (res) {
            var _this = this;
            console.log('FROM WEB: user join',res);
            res.action = 'joins ' + res.target;
            var rendered = $( Mustache.render( _this.tpl_join_part, res ) ); 
            rendered
                .appendTo(log)
            this.log.scrollTop(this.log[0].scrollHeight);

        },
        part : function (res) {
          //_this.ws.send({ source : 'web', action: 'part', channel : chan });
            var _this = this;
            console.log('FROM WEB: user part',res);
            res.action = 'parts from ' + res.target;
            var rendered = $( Mustache.render( _this.tpl_join_part, res ) ); 
            rendered
                .appendTo(log)
            this.log.scrollTop(this.log[0].scrollHeight);
        },
        log : function ( text ) {
            var msg = $('<li/>').html( text ).appendTo( this.log );
        }
    },
    after : {
        initialize: function () {
            this.init();
        },
    },
    before : {
        initialize : function () {
//          jloader.load('./js/handlebars-v3.0.0.js', { eval : false })
//          console.log( Handlebars );
        }
    }
})
