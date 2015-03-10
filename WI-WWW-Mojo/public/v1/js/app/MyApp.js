Class('MyApp', {
    does : [],
    has : {
        deps : {
            is      : "rw",
          //init: (function() {
          //    jloader.load('./js/jquery.min.js', { eval : false })
          //    return [
          //        jloader.load('ClassTest2'),
          //        jloader.load('ClassTest1')
          //    ]
          //})()
        },
        lib_loader  : { is  : "rw" },
        instances   : { is  : "rw", 
        init        : (function(){ return [];})() },
    },
    methods : {
        load_libs : function () {
            var _this = this;
            this.when_done = _this.carregou_libs;
        },
        init : function () {
            var _this = this;
            for (var i=0, myclass; myclass = this.deps[i]; i++) {
              //this.instances.push( new myclass( {
              //    elem        : $( item ),
              //    app   : _this,
              //} )               var myinstance = new myclass();
                var myinstance = new myclass({
                    app : _this
                });
                ( myinstance.init )
                    ? myinstance.init()
                    : undefined
                    ;
              //myinstance.init();
            }
//          $.each( $(selectors), function(i,item) {
//              //console.log( $( item ) );
//              _this.instances.push( new lib( {
//                  elem        : $( item ),
//                  app   : _this,
//              } ) );
//          } ); 
        }
    },
    after : {
        initialize: function () {
            console.log('MyApp inicializada');
        },
//      init: function () { 
//          var _this = this;
//          console.log( _this.instances, 'instances ^^' );
//      }
    },
    before : {
        initialize : function () {
            jloader.load('/v1/js/jquery.js', { eval : false });
            jloader.load('/v1/js/bootstrap.min.js', { eval : false });
            jloader.load('/v1/js/mustache.js', { eval : false });
//          jloader.load('./js/handlebars-v3.0.0.js', { eval : false })
//          console.log( Handlebars );
        }
    }
})
