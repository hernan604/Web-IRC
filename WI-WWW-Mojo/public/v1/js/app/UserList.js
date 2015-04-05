Class('UserList', {
//  does : [ jloader.load('SomeRole') ],
    has : {
        app         : { is : "rw" },
        parent      : { is : "rw" },
        elem        : { is : "rw" },
        selectors   : {
            is   : "rw",
            init : (function () { return '[role=col-left] .user-list' })()
        },
        col_middle  : { is : "rw" },
        user_ul     : { is : 'rw' },
        active      : { is : 'rw' },//the user that is currently opened
        tpl_nick_list    : {
            is : "rw",
            init: ( function () {
                return '\
                <li data-user="{{nick}}"><span class="remove"></span><span class="status"></span>{{nick}}</li>\
                ';
            } )()
        },
    },
    methods : {
        init: function () {
            var _this = this;
            $(document).ready(function () {
                console.log( _this.col_middle );
                console.log('ready');
                jQuery.each( jQuery( _this.selectors, 'body' ) , function(i,item) {
                    var class_name = eval(_this.meta._name);
                    var instance = new class_name({
                        elem        : $(item),
                        app   : _this.app,
                    });
                    instance.start();
                    console.log( _this.app );
                    _this.app.instances.push( instance );
                    _this.app.named_instances['UserList'] = instance;
                }); 
            }); 
        },
        start: function ( args ) {
            var _this = this;
            _this.setCol_middle( $( '[role=col-middle]' ) );
            console.log('start colleft user');
            //var class_test1_dep = new ClassTest1Dep1();
            //this.elem.html( "(ClassTest2 + ClassTest1Dep1)" );
            var ul = $('<ul/>');
            _this.setUser_ul( ul );
            var friends = _this.app.named_instances.User.friends; 
            for ( var i = 0, user; user = friends[i] ; i++ ) {
                if ( user != _this.app.my_nick ) {
                    _this.add_user( user );
                }
            }
            $( '<li/>' )
                .prependTo( ul )
                .html( 'Direct Messages' )
            _this.elem.html( ul );
            _this.get_everyone_status();
        },
        stop : function () {
        },
        bind_events : function ( $markup ) {
            var _this = this;
            $markup
                .click( function ( ev ) {
                    var target = $( ev.currentTarget );
                    var user_name = target.data('user');
                    _this.activate( $( ev.currentTarget ) , user_name );
                    if ( _this.is_user_open( user_name ) ) {
                        console.log('show_user');
                        var user = _this.find_user( user_name );
                        user.show();
                    } else {
                        _this.open_user(user_name);
                    }
                } )
            $markup.find('.remove').click( function ( ev ) {
                var $target = $( ev.currentTarget );
                _this.remove_friend(
                    $target.closest('[data-user]'),
                    $target.closest('[data-user]').data( 'user' ) 
                );
                //remove element from markup
                //remove nick from friendlist
                ev.preventDefault();
                ev.stopPropagation();
            });
            return $markup;
        },
        remove_friend : function ( $target, nick ) {
            var _this = this;
            $target.remove();
            $.ajax({
                url     : '/user/friend/del',
                cache   : false,
                success : function (data) {

                },
                contentType : 'application/json',
                dataType    : 'json',
                type        : 'PUT',
                data        : JSON.stringify({
                    friend  : nick,
                }), 
            });
        },
        add_friend : function ( nick ) {
            var _this = this;
            $.ajax({
                url     : '/user/friend/add',
                cache   : false,
                success : function (data) {

                },
                contentType : 'application/json',
                dataType    : 'json',
                type        : 'PUT',
                data        : JSON.stringify({
                    friend  : nick,
                }), 
            });
        },
        add_user : function ( nick ) {
            var _this = this;
//          var ul = _this.user_ul;
            _this.append_nick( nick );
//          var $markup = _this.bind_events( $( Mustache.render( _this.tpl_nick_list, {nick:nick} ) ) );
//          ul.append( $markup );
        },
        deactivate : function () {
            var _this = this;
            _this.hide_users();
            $.each( $(_this.selectors).find('.active') , function ( i , item ) {
                $( item ).removeClass('active');
            } )
            _this.active = undefined;
        },
        activate : function ( target, user ) {
            //* * Chamar o UserList e desativar.. thirar do active
            var _this = this;
            _this.app.named_instances['ChannelList'].deactivate();
            _this.deactivate();
            $.each( target.parent().find('>li') , function ( i , item ) {
                if ( $( item ).data('user') && $( item ).data('user') == user ) {
                    $( item ).addClass('active');
                    _this.setActive( user );
                    _this.remove_message_counter( $( item ) );
                }
            } )
        },
        is_user_open : function ( user ) {
            var _this = this;
            return _this.col_middle.find('[data-user='+user+']').length;
        }, 
        find_user: function ( user ) {
            //TODO: Change  to find_query instead.
            var _this = this;
            return _this.col_middle.find('[data-user='+user+']');
        },
        hide_users : function () {
            //TODO: Change to hide_query iunstead.
            var _this = this;
            console.log( _this, _this.col_middle, '<- hide_users' );
            $.each( _this.col_middle.find( '[data-user]' ) , function ( i, item ) {
                $(item).hide();
            })
        },
        user_dom : function ( user ) {
            var _this = this;
            return $( '[data-user='+(user||_this.active)+']' );
        },
        current_user_dom : function () {
            var _this = this;
            var current_user = _this.active;
            return $( '[data-user='+current_user+']' );
        },
        tpl_user : function ( user ) {
            return '\
            <div class="container-fluid">\
                <div class="row header">\
                    <ul class="controls">\
                        <li class="users"><span class="count"></span>Users</li>\
                    </ul>\
                </div>\
                <div class="row body">\
                     <ul id="log" user="'+ user +'" readonly></ul>\
                </div>\
                <div class="row footer">\
                    <div class="col-sm-10">\
                        <div class="row">\
                            <textarea type="text" id="msg" placeholder="Enter text here.."/></textarea>\
                        </div>\
                    </div>\
                    <div class="col-sm-2">\
                        <div class="row">\
                            <button class="btn send">Send</button>\
                        </div>\
                    </div>\
                </div>\
            </div>\
            ';
        },
        load_history : function ( user ) {
            var _this = this;
            console.log('loading history' , user);
            $.ajax({
                url     : '/private-message/history',
                cache   : false,
                async   : false,
                success : function (data) {
                    console.log( data, '<- user history' );
                    if ( !data || !data.results ) { return; }
                    for ( var i=0, obj; obj = data.results[i]; i++ ) {
                        console.log( obj, '<- history item' );
//                      _this.process_ws_obj( obj );
                        _this.app.named_instances['AppChatEvent'].private_message( obj );
                    }
                },
                data    : JSON.stringify({
                    nick        : user,
                }),
                contentType   :'application/json',
                dataType      :'json',
                type          : 'PUT'
            }); 
        },
        open_user : function ( user ) {
            //build frame
            var _this = this;
            console.log(_this.col_middle, 'open_user2');
            //1. tell the app this user has joined the user
            $( '<div/>' )
                .addClass( 'user' )
                .attr( 'data-user', user )
                .appendTo( _this.col_middle.find('>.channels') )
                .show()
                .html( _this.tpl_user( user ) )
                ;
            _this.load_history( user );
        },
        event_message : function ( res ) {
            var _this = this ;
            console.log('event_message', res )
            console.log( _this.active );
            var my_nick = _this.app.named_instances[ 'User' ].nick;
            _this.add_friend( res.from );
            if ( res.from != my_nick && _this.active != res.from ) {
                var $target = $('.user-list [data-user="'+res.from+'"]');
                _this.update_message_counter( $target );
            }
        },
        update_message_counter : function ( $elem ) {
            var _this = this;
            console.log( ' update_message_coutner' );
            var $elem_counter = $elem.find( '.message-counter' ); 
            var counter = ( $elem_counter.length ) 
                ? ( function () {
                    var total = $elem_counter.data('value') + 1 ;  
                    $elem_counter.remove()
                    return total;
                } )()
                : 1;

            var $counter_markup = $('<span/>')
                .addClass( 'message-counter' )
                .attr('data-value', counter )
                .html( counter )
                .appendTo( $elem )
                ;
        },
        remove_message_counter : function ( $elem ) {
            $elem.find('.message-counter').remove();
        },
        append_nick : function ( nick ) {
            //will append this nick in the nick list *if nick ! exists already
            //in alphabetical order
            var _this = this;
            if ( nick == _this.app.named_instances.User.nick ) return ;
            var add_nick = function ( nick, elem ) {
                var $markup = _this.bind_events( $( Mustache.render( _this.tpl_nick_list, {nick:nick} ) ) );
                if ( elem ) {
                    $( elem ).before( $markup )
                } else {
                    _this.user_ul.append( $markup );
                }
            }
            if ( ! _this.exist_nick_in_list( nick ) ) {
                var is_nick_added = false;
                var nick_nodes = _this.user_ul.find('li[data-user]');
                if ( ! nick_nodes.length ) {
                    add_nick( nick ) //first nick added in nick list
                } else {
                    $.each( nick_nodes , function( i , item ) {
                        if ( ! is_nick_added 
                            && nick.toLowerCase() < $( item ).data('user').toLowerCase() ) {
                            is_nick_added = true;
                            add_nick( nick, $( item ) )
                            return;
                        }
                    } );
                    if ( ! is_nick_added ) {
                        add_nick( nick )
                    }
                }
            }
        },
        exist_nick_in_list : function ( nick ) {
            var _this = this;
            return $( _this.selectors ).find('li[data-user='+nick+']').length;
        },
        set_status : function ( nick, current_status ) {
            var _this = this;
            if ( _this.exist_nick_in_list( nick ) ) {
                $( _this.selectors )
                    .find('li[data-user='+nick+']')
                    .attr('data-status',current_status)
                    ;
            }
        },
        get_everyone_status : function () {
            var _this = this;
            $.ajax({
                url     : '/everyone-status',
                cache   : false,
                success : function (data) {
                    for ( var i = 0, item ; item = data.results[i] ; i++  ) {
                        _this
                            .set_status( item.username, item.status )
                            ;
                    }
                },
                contentType : 'application/json',
                dataType    : 'json',
                type        : 'GET'
            });
        },
    },
    before : {
//      init: function () {
//          //load deps
//      }
    },
    after : {
        initialize: function () {
          //this.when_done = this.start;
          //this.init();
        }
    }
})
