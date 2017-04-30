
all: compile

compile:
	erl -make

run: compile
	erl -pa ebin/ -eval "application:start(distrData)."

local: compile
	erl -pa ebin/ -eval "application:start(distrDataLocal), distrDataLocal:startRing()"

tests: compile
	erl -sname test -pa ebin/ -eval "application:start(distrData), distrData:startRing()"
