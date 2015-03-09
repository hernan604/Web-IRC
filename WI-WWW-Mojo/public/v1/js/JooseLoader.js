Class( "JooseLoader", {
    has : {
        prefix : {
            is : "rw",
            init: (function() {
                return "./js/";
            } )(),
        },
        extension : {
            is : "rw",
            init: (function () {
                return ".js";
            })()
        },
        loaded_urls : {
            //keeps track of which urls have been loaded.
            is : "rw",
            init : ( function () { return {} } )()
        }
    },
    methods : {
        load : function ( class_name, args ) {
            if ( ! class_name ) return;
            var lib_url = ( /^\.\//.test(class_name)        ||  // ^./
                            /^\/\//.test(class_name)        ||  //^//
                            /^\//.test(class_name)          ||  //^/
                            /^http(s?):\/\//.test(class_name)     //^[a-z+]:\/\/
                          )
                            ? class_name //classname is a url in this case
                            : this.to_url( class_name )
                            ;
            if ( this.is_loaded( lib_url ) ) {
                return this.eval_class_name( class_name , args );
            } else {
                this.loaded_urls[ lib_url ] = 1;
            }

        //                  LOAD_OPTION_1: {
        //                      eval( new Joose.SimpleRequest().getText( lib_url ) );
        //                  }
            if ( this.is_same_domain( lib_url ) ) {
                LOAD_OPTION_2: {
                    var source_code = new Joose.SimpleRequest().getText( lib_url );
                    var script = document.createElement('script');
                    script.type = "text/javascript";
                    script.text = source_code;
                    document.getElementsByTagName('head')[0].appendChild(script);
                }
            } else {
              //var source_code = new Joose.SimpleRequest().getText( lib_url );
                var script = document.createElement('script');
                script.type = "text/javascript";
                script.src = lib_url;
                script.onload = function () {  }
                document.getElementsByTagName('head')[0].appendChild(script);
            }

            return this.eval_class_name( class_name , args );

        },
        eval_class_name : function (class_name, args) {
            return ( args && args.eval === false )
                ? undefined 
                : eval(class_name);
        },
        to_url : function ( class_name ) {
            //transform the class_name into the class path.
            //split on the dot, prepend /js and append .js
            //MyClass                       = /js/MyClass.js
            //MyClass.SubClass.OtherClass   = /js/MyClass/SubClass/OtherClass.js
            return this.prefix + class_name.split('.').join('/') + this.extension
        },
        is_loaded : function ( lib_url ) {
            return this.loaded_urls[ lib_url ];
        },
        is_same_domain : function (lib_url) { 
            var this_domain = window.location.origin;
            var rgx = new RegExp( '^' + this_domain, 'g' );
            var cond = !/^http/.test(lib_url) &&! rgx.test( lib_url );
            return cond;
        }
    }
} )
