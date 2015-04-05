Class('AppChatControlUserlist', {
    does : [],
    has : {
        app  : { is : "rw" },
        parent  : { is : "rw" },
        deps : {
            is  : "rw",
            init: (function(){return [
            ]})(),
        },
        lib_loader  : { is  : "rw" },
        selector    : { is  : 'rw', init: (function () { return '.controls .users' })() },
        target      : { is  : 'rw' }
    },
    methods : {
        load_libs : function () {
            var _this = this;
            this.when_done = _this.carregou_libs;
        },
        init : function () {
            var _this = this;
            $( document ).ready( function () {
                $( document ).on(
                    'click', 
                    _this.selector , 
                    function ( ev ) { _this.open( ev ) } 
                );
                _this.app.instances.push( _this );
                _this.app.named_instances['AppChatControlUserlist'] = _this;
            }); 
        },
        list_users : function ( cb ) {
            var _this = this;
            var current_channel = _this.app.named_instances['ChannelList'].active;
            var url = '/channel/list_users/'+( current_channel.replace(/^#/,'') );
            $.ajax({
                url     : url,
                cache   : false,
                contentType : 'application/json',
                dataType : 'json',
                success : cb,
                type: 'GET'
            }); 
        },
        open : function ( ev ) {
            var _this = this;
            var target = $( ev.currentTarget );
            target.addClass('open').removeClass( 'closed' );
            _this.list_users( function ( data ) { _this.modal_userlist( target, data.results ); } );
        },
        update_user_counter : function ( channel ) {
console.log('update_user_counter');
            var _this = this;
            _this.list_users( function ( data ) { 
                console.log(data,'<--- update user_counter');
                _this.app.named_instances['ChannelList'].channel_dom( channel ).find('.count').html( data.results.length );
            } );
        },
        userlist_tpl : function ( users ) {
            var tpl = "\
                <ul>\
                    {{#users}}\
                        <li class='user' data-user_id='{{user_id}}'>{{username}}</li>\
                    {{/users}}\
                </ul>\
            ";
            var userlist = 
                $( Mustache.render( tpl, { users:users } ) );
            this.bind_userinfo( userlist );
            return userlist;
        },
        bind_userinfo : function ( userlist ) {
            $.each( userlist.find( 'li.user' ) , function(i,item) {
                item = $( item );
                item.click( function ( ev ) {
                    alert( $( ev.currentTarget ).data( 'user_id' ) );
                } );
            }); 
        },
        modal_userlist : function ( target, users ) {
            var _this = this;
            var modal_tpl = '\
                <div class="modal fade backdrop-transparent" id="basicModal" tabindex="-1" role="dialog" aria-labelledby="basicModal" aria-hidden="true">\
                    <div class="modal-dialog">\
                        <div class="modal-content">\
                            <div class="modal-header">\
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&amp;times;</button>\
                            <h4 class="modal-title" id="myModalLabel">{{title}}</h4>\
                            </div>\
                            <div class="modal-body">\
                            </div>\
                            <div class="modal-footer">\
                                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>\
                        </div>\
                    </div>\
                  </div>\
                </div>\
            ';

            var rendered = $( Mustache.render( modal_tpl, {
                title : 'Users from channel'
            } ) );

            rendered.find('.modal-body').append( this.userlist_tpl( users ) );
            rendered.modal('show'); 
        },
    },
    after : {
        initialize: function () {
          //this.init();
        },
    },
    before : {
        initialize : function () {
//          jloader.load('./js/handlebars-v3.0.0.js', { eval : false })
//          console.log( Handlebars );
        }
    }
})
