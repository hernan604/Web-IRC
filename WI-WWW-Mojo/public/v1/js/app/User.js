Class("User", {
    has : {
        nick            : { is : 'rw' },
        app             : { is : 'rw' },
        profile         : { is : 'rw' },
        everyone_status : { is : 'rw' },
        friends         : { is : 'rw' , init: ( function () { return [] } )()},
    },
    methods : {
        get_info : function () {
            var _this = this;
            $.ajax({
                url     : '/user/profile',
                cache   : false,
                async   : false,
                success : function (data) {
                    _this.setNick( data.nick );
                    _this.setFriends( data.friends );
//                  console.log( data.profile , '<- profile' );
                },
                contentType : 'application/json',
                dataType    : 'json',
                type        : 'GET'
            }); 
        },

        init : function () { 
            this.app.named_instances.User = this;
            this.get_info();
        }
    },
    after : {
        setNick : function ( nick ) {
            var _this = this;
            _this.app.setMy_nick( nick );
        }
    }
})
