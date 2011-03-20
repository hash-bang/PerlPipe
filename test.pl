use Test::Simple tests => 19;

ok(`echo 'foo bar baz' | pp m/bar/` eq "foo bar baz\n", 'Simple m// return');
ok(`echo "foo\nbar\nbaz\n" | pp m/bar/` eq "bar\n", 'Simple m// multiline return');
ok(`echo 'foo bax baz' | pp m/bar/` eq "", 'Simple m// failed return');
ok(`echo "foo\nbar\nbaz\n" | pp m/barX/` eq "", 'Simple m// multiline failed return');
ok(`echo 'foo bar baz' | pp 'm/(b..)/'` eq "bar\n", 'Capture return');
ok(`echo "foo\nbar\nbaz\n" | pp 'm/^b(..)\$/'` eq "ar\naz\n", 'Capture multiline return');
ok(`echo 'foo bar baz' | pp -c 'm/b../'` eq "bar\n", 'CLI (-c) capture return');
ok(`echo "foo\nbar\nbaz\n" | pp -c 'm/^b..\$/'` eq "bar\nbaz\n", 'CLI capture multiline return');
ok(`echo 'foo bar baz' | pp 's/bar/XXX/'` eq "foo XXX baz\n", 'Simple replacement');
ok(`echo 'foo bar baz' | pp 's/bar/XXX/' 's/XXX/ZZZ/' 's/(z..)/X\\L\\1\\E/i'` eq "foo Xzzz baz\n", 'Compound replacement');
ok(`echo "foo\nbar\nbaz" | pp 'm/^b' 's/(..)\$/\\U\\1\\E/'` eq "bAR\nbAZ\n", 'Compound multiline match + replacement');
ok(`echo "foo\nbar\nbaz" | pp 'm/^x' 's/(..)\$/\\U\\1\\E/'` eq "", 'Compound multiline failed match + replacement');
ok(`echo "foo bar baz" | pp uc` eq "FOO BAR BAZ\n", 'UC function');
ok(`echo "foo bar baz" | pp uc lc` eq "foo bar baz\n", 'UC + LC function');
ok(`echo "foo\nbarx\nbazxx\n" | pp uc lc length` eq "3\n4\n5\n0\n", 'Compound function usage');

# Aliases
ok(`echo "/foo/bar/baz" | pp basename` eq "baz\n", 'Basename alias');
ok(`echo "/foo/bar/baz" | pp dirname` eq "/foo/bar\n", 'Dirname alias');
ok(`echo " foo bar baz    " | pp trim` eq "foo bar baz\n", 'Trim alias');
ok(`echo "   /foo/bar/baz   " | pp dirname basename trim` eq "bar\n", 'Compound alias');
