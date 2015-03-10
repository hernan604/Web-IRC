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
                                    <label for="title">Channel name (ie. #channel #channel-name)</label>\
                                    <input id="name" class="form-control" type="email" placeholder="channel-name">\
                                    <p class="help-block">Use only letters or numbers. Dont use accents, dont start with numbers, dont use spaces and neither special characters.</p>\
                                    </div>\
                                </div>\
                            </div>\
                            <div class="modal-footer">\
                                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>\
                                <button type="button" class="btn btn-primary join">Join channel</button>\
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
        activate : function ( target, chan ) {
            $.each( target.parent().find('>li') , function ( i , item ) {
                $( item ).removeClass('active');
console.log( $( item ).text(), chan );
                if ( $( item ).text() == chan ) 
                    $( item ).addClass('active');
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
        open_chan : function ( chan ) {
            console.log('open_chan');
            //build frame
            var _this = this;
            var iframe = $('<iframe/>')
                .attr('data-chan', chan)
                .attr('src', '/chat/'+chan )
                .appendTo( _this.col_middle.find('>.channels') )
                .show()
                ;

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
