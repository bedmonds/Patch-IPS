Patch::IPS
==========

Apply and create binary file patches in the IPS format.


## Synopsis

```perl6
use Patch::IPS qw<apply>;

Patch::IPS.apply(
  patch => '/home/able/baker/cooking.ips',
  target => '/home/kitchen/staff.nes',
  outfile => '/home/kitchen/delicious-cookies.nes'
);
```


## Description

IPS is a format that is still widely used by the ROM hacking community.

This provides a simple API to generate a patch by comparing two files, 
and to apply an existing patch to a file.


## Copyright and License

This is free software.

Please see the [LICENSE] file in this directory.

© 2018 Brian Edmonds 


## Maintainer

Brian Edmonds <[brian@bedmonds.net]>


[LICENSE]: LICENSE
[brian@bedmonds.net]: mailto:brian@bedmonds.net
