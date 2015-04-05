Class('ColLeft', {
//  does : [ jloader.load('SomeRole') ],
    has : {
        app : { is : "rw" },
        elem : { is : "rw" },
//      selectors   : {
//          is : "rw",
//          init : (function () { return '.class-test2,.class-test2-other-selector' })()
//      },
        deps : {
            is      : "rw",
            init    : (function() {
                return [
                    jloader.load('ChannelList'),
                    jloader.load('UserList'),
                ]
            } )()
        },
    },
    methods : {
        init: function () {
            var _this = this;
            for (var i=0, myclass; myclass = this.deps[i]; i++) {
                var myinstance = new myclass({
                    app     : _this.app,
                    parent  : _this,
                });
                ( myinstance.init )
                    ? myinstance.init()
                    : undefined
                    ;
            }
        },
        start: function ( args ) {
//          var class_test1_dep = new ClassTest1Dep1();
//          this.elem.html( "(ClassTest2 + ClassTest1Dep1) - time now :" );
        },
        stop : function () {
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
