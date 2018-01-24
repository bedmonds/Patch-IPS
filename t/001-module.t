use lib 'lib';
use Test;

plan 3;

use-ok('Patch::IPS');

use Patch::IPS;

my $null = IO::Path.new('/dev/null');

ok(&apply.defined, 'apply function exists');
ok(&create.defined, 'create function exists');
