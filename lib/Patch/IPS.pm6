=begin pod

=head1 NAME

Patch::IPS - Apply and create binary file patches in the IPS format


=head1 DESCRIPTION

IPS is a format that is still widely used by the ROM hacking community.

This provides a simple API to generate a patch by comparing two files, 
and to apply an existing patch to a file.

=end pod

unit module Patch::IPS;


use experimental :pack;

constant ips-header = 'PATCH'.encode(:enc<bin>);
constant ips-footer = 'EOF'.encode(:enc<bin>);


subset Address of Int where 0 <= * < 16777216; 

role Instruction {
	method call(Buf $rom --> Buf) { ... }
}

# Standard IPS instruction, consisting of a
# 5 byte header, followed by the payload.
class Record does Instruction {
	# 3 bytes, where to place the payload.
	has Address $!offset;
	# 2 bytes, the length in bytes of the payload in big endian.
	has uint8 $!length;
	# The data to write from $!offset, overwriting anything
	# in its way.
	has Buf $!payload;


	method call(Buf $rom --> Buf) {
		my $buf = $rom.clone;
		$buf.subbuf-rw($!offset, $!length) = $!payload;
		return $buf;
	}
}


class RLE does Instruction {
	has Address $!offset;
	has uint8 $!length;
	has Buf $!payload;

	method call(Buf $rom --> Buf) {
		my $buf = $rom.clone;
		$buf.subbuf-rw($!offset, $!length) = Buf.allocate($!length, $!payload);
		return $buf;
	}
}


class PatchFile {
	has Buf $!header;
	has @!ops;
	has Buf $!footer;

	submethod BUILD(Str :$path!) {
		$path.IO ~~ :r || die("Cannot open file $path for reading");

		with $path.IO {
			my $fh will leave { .close } = .open;
			$fh.encoding: Nil;

			my $data;
			$data = $fh.slurp;

			$!header = $data.subbuf(0, 5);
			$!footer = $data.subbuf(*-3);

			@!ops = parse-instructions($data.subbuf(5, $data.bytes - 8));
		}
	}

	method is-valid {
		return $!header eq ips-header && $!footer eq ips-footer;
	}
}


# Extract a set of instructions, which can either standard IPS op
# or a compressed RLE op.
sub parse-instructions(Buf $buf, @ops?) {
	@ops = Array[Instruction].new unless @ops;
	return @ops if $buf.bytes == 0;

	my $addr = Blob.new([0] + $buf.subbuf(0,3)).unpack('N');
	my $size = $buf.subbuf(3, 2).unpack('n');
	my $nbuf;


	if $size == 0 {
		my $rel-size = $buf.subbuf(5, 2).unpack('n');
		@ops.push(RLE.new(
			offset => $addr,
			length => $rel-size,
			payload => $buf.subbuf(7, $rel-size)
		));

		$nbuf = $buf.subbuf($rel-size + 7);
	} else {
		@ops.push(Record.new(
			offset => $addr, 
			length => $size, 
			payload => $buf.subbuf(5, $size)
		));

		$nbuf = $buf.subbuf($size + 5);
	}

	return parse-instructions($nbuf, @ops);
}

# Validate that a file is an IPS patch.
sub is-ips(Str $patch --> Bool) {
	return False unless $patch.IO.f;
	die("Cannot open file $patch") unless $patch.IO ~~ :r;

	my $fh = $patch.IO.open;
	LEAVE try close $fh;

	return $fh.readchars(5) eq 'PATCH';
}


# Apply the IPS file $patch to the target file $target. 
# The patch will be applied in-place unless an $outfile is supplied.
sub apply(
	# An IPS format patch file	
	Str :$patch!,
	# File on which to apply the patch
	Str :$target!, 
	# (optional) Save the patched file to this location
	Str :$outfile
) is export {
PatchFile.new(path => '/home/artea/src/ffrestored/FF Restored/Settings/RNG - Improved.ips');
}


# Generate an IPS patch by diffing two binary files.
sub create(
	# File before modifications
	Str :$original!,
	# Modified file on which to extrapolate the patch
	Str :$modified!,
	# Target path to the generated IPS patch
	Str :$outfile!
) is export {

}
