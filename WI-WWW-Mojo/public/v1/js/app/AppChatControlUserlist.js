Class('AppChatControlUserlist', {
    does : [],
    has : {
        app  : { is : "rw" },
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
                     if ( _this.target.hasClass( 'open' ) ) {
                         _this.close();
                     } else {
                         _this.open();
                     }
                } );
            }); 
        },
        open : function () {
            this.target.addClass('open').removeClass('closed');
            alert('show users');
        },
        close : function () {
            this.target.addClass('closed').removeClass('open');
            alert('hide users');
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
