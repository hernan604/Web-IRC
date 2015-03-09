-- 1 up

CREATE TABLE "User" (
    id serial NOT NULL,
    email text,
    username text,
    password text,
    name text,
    CONSTRAINT "User_pkey" PRIMARY KEY (id)
);

-- 2 up

CREATE TABLE "Channel" (
    id serial NOT NULL,
    name text,
    topic text,
    modes text,
    CONSTRAINT "Channel_pkey" PRIMARY KEY (id)
);

CREATE TABLE "ChannelLog" (
    id serial   NOT NULL,
    channel_id  INTEGER NOT NULL REFERENCES "Channel"(id),
    line text,
    user_id     INTEGER NOT NULL REFERENCES "User"(id),
    created     timestamp without time zone default (now() at time zone 'utc'),
    PRIMARY KEY ( id )
);

-- 3 up

-- 4 up

ALTER TABLE "ChannelLog" ADD COLUMN source text;

-- 5 up

ALTER TABLE "ChannelLog" ADD COLUMN action text;
