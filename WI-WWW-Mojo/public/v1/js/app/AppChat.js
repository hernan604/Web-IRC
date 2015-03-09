Class('AppChat', {
    does : [],
    has : {
        deps : {
            is  : "rw",
            init: ( function() {
                var deps = [
                    jloader.load('AppChatControl'),
                    jloader.load('AppChatEvent'),
                ];
                console.log(deps);
                return deps;
            } )()
        },
        lib_loader  : { is  : "rw" },
        instances   : {
            is      : "rw", 
            init    : (function(){ return [];})() 
        },
        ws          : { is  : "rw" },
        channel     : { is  : 'rw' },
        control     : { is  : 'rw' },
        event       : { is  : 'rw' },
    },
    methods : {
        load_libs : function () {
            var _this = this;
            this.when_done = _this.carregou_libs;
        },
        init : function () {
            var _this = this;
            $(document).ready(function () {
                _this.setEvent( new AppChatEvent( {
                    channel : _this.channel,
                    app     : _this,
                    ws      : _this.ws,
                } ) );

                _this.setControl( new AppChatControl( {
                    app     : _this,
                } ) );
            }); 
//          console.log('xx',this.deps);
//          for ( var i=0, myclass; myclass = this.deps[i]; i++ ) {
//              console.log(myclass )
//              if ( myclass == 'AppChatEvent' ) continue;
//              var myinstance = new myclass({
//                  app : _this
//              });
//              ( myinstance.init )
//                  ? myinstance.init()
//                  : undefined
//                  ;
//          }            
        }
    },
    after : {
        initialize: function () {
            console.log('AppChat inicializada');
        },
//      init: function () { 
//          var _this = this;
//          console.log( _this.instances, 'instances ^^' );
//      }
    },
    before : {
        initialize : function () {
            jloader.load('/v1/js/jquery.js', { eval : false })
            jloader.load('/v1/js/mustache.js', { eval : false })
//          jloader.load('./js/handlebars-v3.0.0.js', { eval : false })
//          console.log( Handlebars );
        }
    }
})
