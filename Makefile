
all: compile

compile:
	erl -make

run: compile
	erl -pa ebin/ -eval "application:start(distrData)."

tests: compile
	erl -pa ebin/ -eval "application:start(tests), distrData:startRing()"
