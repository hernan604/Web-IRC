Class('AppLogin', {
    does : [],
    has  : {
        app  : { is : "rw" },
        deps : {
            is  : "rw",
            init: (function(){return [
              //jloader.load('AppChatPluginYoutube')
            ]})(),
        },
        instances   : {
            is    : "rw", 
            init  : (function(){ return [];})()
        },
        channel     : { is  : 'rw' },
        ws          : { is  : 'rw' },
        log         : { is  : 'rw' },
        plugins     : { is  : 'rw' },

        username    : { is  : 'rw' },
        password    : { is  : 'rw' },
        email       : { is  : 'rw' },
        btn_login   : { is  : 'rw' },
        btn_signup  : { is  : 'rw' },
        btn_register: { is  : 'rw' },
    },
    methods : {
        init : function () {
            var _this = this;
            $(document).ready(function () {
                _this.setUsername( $( '#username' ) );
                _this.setPassword( $( '#password' ) );
                _this.setEmail( $( '#email' ) );
                _this.setBtn_login( $( '.btn.login' ) );
                _this.setBtn_signup( $( '.btn.signup' ) );
                _this.setBtn_register( $( '.btn.register' ) );
                _this.bind_login();
                _this.bind_register();
                _this.bind_signup();
            }); 
        },
        bind_register : function () {
            var _this = this;
            $('.btn.register').click(
                function () {
                    if ( _this.validate_registration() ) {
                        _this.register()
                    } else {
                        _this.show_error( ['Registration failed'] )
                    }
            } )
        },
        bind_login : function () {
            var _this = this;
            this.btn_login.click( 
                function () {
                    if ( _this.validate() ) {
                        _this.login() 
                    } else {
                        _this.show_error( ['Registration failed'] ) 
                    }
            } )
        },
        bind_signup : function () {
            var _this = this;
            this.btn_signup
                .click( function ( ev ) {
                    window.location = $( ev.currentTarget ).data('href');
                } )
                
        },
        register : function () {
            $('.login .errors').html('');
            var _this = this;
            console.log('check if login exists, or is taken')
            $.ajax({
                url     : '/signup',
                cache   : false,
                success : function (data) {
                    if ( data.status == 'OK' ) {
                      //window.location = data.redirect;
                        _this.show_error( [
                            'To finish sign-up please confirm your email.',
                            'Check your inbox and click the link.' 
                        ] );
                    } else {
                        _this.show_error( data.errors );
                    }
                },
                data    : JSON.stringify({
                    username : _this.username.val(),
                    password : _this.password.val(),
                    email    : _this.email.val(),
                }),
                contentType   :'application/json',
                dataType      :'json',
                type          : 'PUT'
            }); 
        },
        validate : function () {
            console.log('valudate');
            return this.username.val().length && this.password.val().length
        },
        validate_registration : function () {
            console.log('valudate');
            return this.username.val().length 
                && this.password.val().length 
                && this.email.val().length
        },
        login : function () {
            $('.login .errors').html('');
            var _this = this;
            console.log('make POST and make user authenticate')
            $.ajax({
                url     : '/login',
                cache   : false,
                success : function (data) {
                    if ( data.status == 'OK' ) {
                        window.location = data.redirect;
                    } else {
                        _this.show_error( data.errors );
                    }
                },
                data    : JSON.stringify({
                    username : _this.username.val(),
                    password : _this.password.val()
                }),
                contentType   :'application/json',
                dataType      :'json',
                type          : 'PUT'
            }); 
        },
        show_error : function ( errors ) {
            var ul_errors = $('.login .errors');
            ul_errors.html('');
            for ( var e = 0, error ; error = errors[ e ]; e++ ) {
                $('<li/>')
                    .html( error )
                    .appendTo( ul_errors )
            }
        }
    },    
    after : {
        initialize: function () {
            this.init();
        },
    },
    before : {
        initialize : function () {
            jloader.load('/v1/js/jquery.js', { eval : false })
        }
    }
})
