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
            var channels = ['#systems','#padrao','#teste','#apps'];
            for ( var i = 0, chan; chan = channels[i] ; i++ ) {
                _this.add_chan( chan, ul );
            }
            this.elem.html( ul );
        },
        stop : function () {
        },
        add_chan : function (chan, ul) {
            var _this = this;
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
