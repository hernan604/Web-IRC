Class('AppChatControl', {
    does : [],
    has : {
        app  : { is : "rw" },
        deps : {
            is  : "rw",
            init: (function(){return [
                jloader.load('AppChatControlUserlist')
            ]})(),
        },
        lib_loader  : { is  : "rw" },
        instances   : {
            is    : "rw", 
            init  : (function(){ return [];})()
        },
    },
    methods : {
        load_libs : function () {
            var _this = this;
            this.when_done = _this.carregou_libs;
        },
        init : function () {
            var _this = this;
            console.log('iinit control');
            for (var i=0, myclass; myclass = this.deps[i]; i++) {
            console.log('iinit '+myclass);
                var myinstance = new myclass({
                    app : _this.app,
                    parent : _this,
                });
                ( myinstance.init )
                    ? myinstance.init()
                    : undefined
                    ;
            }
        },
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
