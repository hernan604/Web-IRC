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
        rnd : { is : 'rw', init: ( function() { return Math.random() })() },
//      channel     : { is  : 'rw' },
//      ws          : { is  : 'rw' },
//      log         : { is  : 'rw' },
        plugins     : { is  : 'rw' },
        is_initialized : { is : 'rw', init: (function () { return false } )() },
        tpl_join_part: {
            is : 'rw',
            init : (function () {
                var tpl = "\
                <li class='row msg'>\
                <div class='col-sm-1'><div class='row photo userpic'></div></div>\
                <div class='col-sm-11'><div class='row'><span class='username'>{{nick}}</span><span class='date'>{{hms}}</span></div><div class='row'><span class='notice'>{{action}}</span></div></div>\
                <\li>\
                "; 
                return tpl;
            })()
        },
        tpl_pvt: {
            is : 'rw',
            init : (function () {
                var tpl = '\
                <li class="row msg">\
                    <div class="col-sm-1">\
                        <div class="row photo userpic"></div>\
                    </div>\
                    <div class="col-sm-11">\
                        <div class="row">\
                            <span class="username">{{from}}</span>\
                            <span class="date">{{created}}</span>\
                        </div>\
                        <div class="row">\
                            <span>{{line}}</span>\
                        </div>\
                    </div>\
                </li>\
                '; 
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
            this.setIs_initialized( true );
            jloader.load('AppChatPluginYoutube');
            this.setPlugins([
                new AppChatPluginYoutube()
            ]);

            this.init_ws();
            _this.app.instances.push( _this );
            _this.app.named_instances['AppChatEvent'] = _this;
        },
        process_ws_obj : function ( obj, extra ) {
            var _this = this;
//          console.log( 'RECEIVED MESSAGE' );
//          console.log( obj );
                 if ( obj.action == 'message' )   { _this.msg(obj, extra)  }
            else if ( obj.action == 'join' )      { _this.join(obj, extra) }
            else if ( obj.action == 'part' )      { _this.part(obj, extra) }
            else if ( obj.action == 'private-message' )      { _this.private_message(obj, extra) }
            else if ( obj.action == 'connect' )      { _this.connect(obj, extra) }
            else if ( obj.action == 'disconnect' )      { _this.disconnect(obj, extra) }
            else { console.log(obj, '<- UNKNOWN MSG' ) }
        }, 
        init_ws : function () {
            console.log('INIT WS');
            var _this = this;
//          $('#msg').focus();
            var ws_url = 'ws://' + window.location.host + '/chat_ws/';
        
            var ws      = new WebSocket( ws_url );
            _this.app.ws = ws

            ws.onopen = function () {
                console.log('Connection opened');
//              _this.app.named_instances.User.get_profile();
console.log( '* * * * * ATIVAT A OPCAO ACIMA... get_profile ... pra atualizar o meu profile.');
            };
            ws.onmessage = function ( obj ) {
                console.log( "ws onmessage", obj );
                _this.process_ws_obj( JSON.parse( obj.data ), { is_live_event : true } );
            };

            $( document ).on( 'keydown', '[id=msg]', function ( ev ) {
                var item = $( ev.currentTarget );
                if ( ev.keyCode == 13 && item.val( ) ) {
                    _this.submit( (item.closest( '[data-chan]' ).data('chan')
                                 ||item.closest( '[data-user]' ).data('user')
                    ), item );
                }
            } )

            $( document ).on( 'click', '.btn.send', function ( ev ) {
                var $item = $( ev.currentTarget );
                var $msg = chan.find( '[id=msg]' );
                _this.submit( $item.closest( '[data-chan]' ).data('chan')
                            ||$item.closest( '[data-user]' ).data('user')
                , $msg );
            } )
        },
        submit : function ( target, $msg ) {
            console.log( 'submit to: ', target, ' value: ', $msg.val() );
            var _this = this;
            var data = { 
                source  : 'web', 
                line    : $msg.val(),
            };
            if ( target.match(/^#/) ) {
                data.chan = target;
                data.action  = 'message';
            } else {
                data.to = target;
                data.action  = 'private-message';
            }
 
            data = JSON.stringify( data );
            console.log( "sent: " , data  );
            _this.app.ws.send( data );
            setTimeout( function () { 
                $msg.val('');
            } , 10 )
        },
        connect : function ( res, extra ) {
            var _this = this;
            //tru to update user status from USerList
            //try to update my status.
            _this.app.named_instances['UserList'].set_status( res.nick, res.status );
        },
        disconnect : function ( res, extra ) {
            var _this = this;
            //tru to update user status from USerList
            //try to update my status.
            _this.app.named_instances['UserList'].set_status( res.nick, res.status );
        },
        private_message : function ( res, extra ) {
            var _this = this;
            var messages_log = $('.user[data-user='+ res.to +'] [id=log],.user[data-user='+ res.from +'] [id=log]')

            _this.app.named_instances['UserList'].append_nick( res.from );
            _this.app.named_instances['UserList'].event_message(res);

            var rendered = $( Mustache.render( _this.tpl_pvt, res ) ); 
            rendered
                .appendTo(messages_log)
            messages_log.scrollTop(messages_log[0].scrollHeight);
        },
        msg : function ( res, extra ) {
            var _this = this;
            for ( var i = 0, plugin; plugin = this.plugins[ i ] ; i++ ) {
                res.line = plugin.process( res.line );
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

            var text = $('<span/>')
                .html( res.line )
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

            this.app.named_instances['ChannelList'].event_message(res);
            if ( res.channel.match( /^#/ ) ) {
                var messages_log = $('.channel[data-chan='+ res.channel +'] [id=log]');
                msg_markup.appendTo( messages_log )
                messages_log.scrollTop(messages_log[0].scrollHeight);
            } else {
                console.log( 'Private Message' );
            }

//          msg_markup
//              .appendTo(log)
//          this.log.scrollTop(this.log[0].scrollHeight);
        },
        join : function ( res, extra ) {
            var _this = this;
            var messages_log = $('.channel[data-chan='+ res.channel +'] [id=log]');
            if ( extra && extra.is_live_event && ! messages_log.find( '>li' ).length ) {
                console.log(messages_log.find( '>li' ).length) 
                _this.history( res.channel , res.last_msg_id );
            }

//          console.log('FROM WEB: user join',res);
            res.action = 'joins ' + res.channel;
            _this.render_join( messages_log, res );
            messages_log.scrollTop(messages_log[0].scrollHeight);
            if ( extra && extra.is_live_event ) {
                _this.app.named_instances['AppChatControlUserlist'].update_user_counter( res.channel );
            }
        },
        render_join : function ( messages_log, res ) {
            var _this = this; 
            var rendered = $( Mustache.render( _this.tpl_join_part, res ) ); 
            rendered
                .appendTo(messages_log)
        },
        part : function (res, extra) {
          //_this.ws.send({ source : 'web', action: 'part', channel : chan });
            var _this = this;
            res.action = 'parts from ' + res.channel;
            var rendered = $( Mustache.render( _this.tpl_join_part, res ) ); 
            var messages_log = $('.channel[data-chan='+ res.channel +'] [id=log]');
            rendered
                .appendTo(messages_log)
            messages_log.scrollTop(messages_log[0].scrollHeight);
//          _this.app.named_instances['AppChatControlUserlist'].update_user_counter( res.channel );
        },
        log : function ( text ) {
            var msg = $('<li/>').html( text ).appendTo( this.log );
        },
        history : function ( channel, last_msg_id ) {
            var _this = this;
            var dt = new Date();
            if ( ! channel || ! last_msg_id ) return;
            $.ajax({
                url     : '/channel/history',
                cache   : false,
                async   : false,
                success : function (data) {
//                  console.log( data, '<- history' );
                    if ( !data || !data.results ) { return; }
                    for ( var i=0, obj; obj = data.results[i]; i++ ) {
//                      console.log( obj, '< - OBJ' );
                        _this.process_ws_obj( obj );
                    }
                },
                data    : JSON.stringify({
                    id          : last_msg_id,
                    channel     : channel,
                }),
                contentType   :'application/json',
                dataType      :'json',
                type          : 'PUT'
            }); 
        },
    },
    after : {
        initialize: function () {
          //if ( ! this.is_initialized ) {
          //    this.init();
          //}
        },
    },
    before : {
        initialize : function () {
//          jloader.load('./js/handlebars-v3.0.0.js', { eval : false })
//          console.log( Handlebars );
        }
    }
})
