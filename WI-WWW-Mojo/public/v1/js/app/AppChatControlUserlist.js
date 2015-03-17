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
            $(document).ready(function () {
                _this.setTarget( $(_this.selector) );
                console.log( 'bind' );
                _this.target.click( function () {
                    _this.open();
                } );
            }); 
        },
        open : function () {
            var _this = this;
            this.target.addClass('open').removeClass('closed');
            var url = '/channel/list_users/'+(_this.app.channel.replace(/^#/,''));
            $.ajax({
                url     : url,
                cache   : false,
                contentType : 'application/json',
                dataType : 'json',
                success : function (data) {
                    _this.modal_userlist( data.result );
                },
                type: 'GET'
            }); 
        },
        modal_userlist : function ( users ) {
            var _this = this;

            var userlist = '';
            for ( var i = 0, user; user = users[ i ] ; i++ ) {
                userlist += ( ( i == 0 ) ? '' : ', ' ) + user.username;
            }

            console.log( userlist , '<- userlist' );
            var modal_tpl = '\
                <div class="modal fade backdrop-transparent" id="basicModal" tabindex="-1" role="dialog" aria-labelledby="basicModal" aria-hidden="true">\
                    <div class="modal-dialog">\
                        <div class="modal-content">\
                            <div class="modal-header">\
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&amp;times;</button>\
                            <h4 class="modal-title" id="myModalLabel">{{title}}</h4>\
                            </div>\
                            <div class="modal-body">\
                                '+ userlist+'\
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

            rendered.modal('show'); 


        },
        add_chan : function (chan ) {
            var _this = this;
            var ul = _this.channel_ul;
            var li = $('<li/>');
            li.html( chan )
                .appendTo( ul )
                .attr( 'data-chan', chan.replace(/^#/,'') )
                .click( function ( ev ) { 
                    var target = $( ev.currentTarget );
                    var chan_name = target.data('chan');
                    _this.activate( $( ev.currentTarget ) , '#' + chan_name );
                    _this.hide_chans();
                    if ( _this.is_chan_open( chan_name ) ) {
                        console.log('show_chan');
                        var chan = _this.find_chan( chan_name );
                        chan.show();
                    } else {
                        _this.open_chan(chan_name);
                    }
                } )
                ;
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
