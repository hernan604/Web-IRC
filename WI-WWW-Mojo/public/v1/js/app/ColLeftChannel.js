Class('ColLeftChannel', {
//  does : [ jloader.load('SomeRole') ],
    has : {
        app     : { is : "rw" },
        parent  : { is : "rw" },
        elem    : { is : "rw" },
        selectors   : {
            is   : "rw",
            init : (function () { return '[role=col-left] .channel-list' })()
        },
        col_middle : { is : "rw" },
        channel_ul : { is : 'rw' },
        active : { is : 'rw' },//the channel that is currently opened
//      deps : {
//          is      : "rw",
//          init    : (function() {
//              return [
//                  './js/jquery.min.js',
//                  jloader.load('ClassTest1Dep1')
//              ]
//          } )()
//      },
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
                    _this.app.named_instances['ColLeftChannel'] = instance;
                }); 
            }); 
        },
        start: function ( args ) {
            var _this = this;
            _this.setCol_middle( $( '[role=col-middle]' ) );
            console.log('start colleft channel');
            //var class_test1_dep = new ClassTest1Dep1();
            //this.elem.html( "(ClassTest2 + ClassTest1Dep1)" );
            var ul = $('<ul/>');
            _this.setChannel_ul( ul );
            var channels = ['#systems','#padrao','#teste','#apps'];
            for ( var i = 0, chan; chan = channels[i] ; i++ ) {
                _this.add_chan( chan );
            }
            var btn_new_chan = $( '<li>' )
                .addClass( 'new-chan' )
                .click( function ( ev ) {
                    _this.modal_join_channel( ev );
                } )
                .prependTo( ul )
                .html( 'join channel ...' )
                ;

            this.elem.html( ul );
        },
        stop : function () {
        },
        modal_join_channel : function ( ev ) {
            var _this = this;
            var modal_tpl = '\
                <div class="modal fade" id="basicModal" tabindex="-1" role="dialog" aria-labelledby="basicModal" aria-hidden="true">\
                    <div class="modal-dialog">\
                        <div class="modal-content">\
                            <div class="modal-header">\
                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&amp;times;</button>\
                            <h4 class="modal-title" id="myModalLabel">{{title}}</h4>\
                            </div>\
                            <div class="modal-body">\
                                <div class="row">\
                                    <div class="form-group">\
                                    <label for="title">Channel name (ie. channel channel-name)</label>\
                                    <input id="name" class="form-control" type="email" placeholder="channel-name">\
                                    <p class="help-block">Use only letters or numbers. Dont use accents, dont start with numbers, dont use spaces and neither special characters.</p>\
                                    </div>\
                                </div>\
                            </div>\
                            <div class="modal-footer">\
                                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>\
                                <button type="button" class="btn btn-success join">Join channel</button>\
                        </div>\
                    </div>\
                  </div>\
                </div>\
            ';

            var rendered = $( Mustache.render( modal_tpl, {
                title : 'Enter a new channel'
            } ) );

            var input = rendered.find('#name')
                .keyup( function ( ev ) {
                    var target = $( ev.currentTarget );
                  //var last_char = target.val().replace(/(.*)(.)$/g,'$2');
                    var btn_join = rendered.find('.join');
                    if ( target.val().length && /[^a-zA-Z0-9-]/.test( target.val() ) ) {
                        target.addClass('has-error');
                        btn_join.addClass('disabled').removeClass('btn-primary');
                    } else {
                        target.removeClass('has-error');
                        btn_join.addClass('btn-primary').removeClass('disabled');
                    }
                } );

            var btn_join = rendered.find('.join');
            btn_join.click( function ( ev ) {
                var chan_name = '#'+input.val();
                if ( chan_name.length ) {
                    if ( input.hasClass( 'has-error' ) ) return;
                    //add channel in list
                    //trigger click in that channel
                    _this.add_chan( chan_name );
                    $('[data-chan="'+input.val()+'"]').click();
                    rendered.modal('hide'); 
                }
            } )

            rendered.modal('show'); 


        },
        add_chan : function (chan ) {
            var _this = this;
            var ul = _this.channel_ul;
            var li = $('<li/>');
            li.html( chan )
                .appendTo( ul )
                .attr( 'data-chan', chan )
                .click( function ( ev ) { 
                    var target = $( ev.currentTarget );
console.log('Clicked , ', target);
                    var chan_name = target.data('chan');
                    _this.activate( $( ev.currentTarget ) , chan_name );
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
        activate : function ( target, chan ) {
            var _this = this;
            $.each( target.parent().find('>li') , function ( i , item ) {
                $( item ).removeClass('active');
                console.log( $( item ).text(), chan );
                if ( $( item ).data('chan') && $( item ).data('chan') == chan ) {
                    $( item ).addClass('active');
                    _this.setActive( chan );
                    _this.remove_message_counter( $( item ) );
                }
            } )
        },
        is_chan_open : function ( chan ) {
            return this.col_middle.find('[data-chan='+chan+']').length;
        }, 
        find_chan: function ( chan ) {
            return this.col_middle.find('[data-chan='+chan+']');
        },
        hide_chans : function () {
            $.each( this.col_middle.find( '[data-chan]' ) , function ( i, item ) {
                $(item).hide();
            })
        },
        tpl_channel : function ( channel ) {
            return '\
            <div class="container-fluid">\
                <div class="row header">\
                    <ul class="controls">\
                        <li class="users">Users</li>\
                    </ul>\
                </div>\
                <div class="row body">\
                     <ul id="log" chan="'+ channel +'" readonly></ul>\
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
        open_chan : function ( chan ) {
            console.log('open_chan');
            //build frame
            var _this = this;
        //  var iframe = $('<iframe/>')
        //      .attr('data-chan', chan)
        //      .attr('src', '/chat/'+chan )
        //      .appendTo( _this.col_middle.find('>.channels') )
        //      .show()
        //      ;
            //1. tell the app this user has joined the channel
            $.ajax( {
                url     : '/channel/join/'+chan.replace(/^#/,''),
                cache   : true,
                success : function ( data ) {
                    console.log( data );
                    if ( data.status == 'OK' ) {
                        //2. create a div to print events that happpend in that channel
                        var channel = $( '<div/>' )
                            .addClass( 'channel' )
                            .attr( 'data-chan', chan )
                            .appendTo( _this.col_middle.find('>.channels') )
                            .show()
                            .html( _this.tpl_channel( chan ) )
                            ;
                    } else {
                        console.error( 'could not join chan: ' + chan );
                    }
                },
                type    : 'GET'
            } );
        },
        event_message : function ( res ) {
            var _this = this ;
            console.log('event_message', res )
            console.log( _this.active );
            if ( _this.active != res.target ) {
                var $target = $('.channel-list [data-chan="'+res.target+'"]');
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
        }
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
