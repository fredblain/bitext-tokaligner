#! /usr/bin/perl -w
#
# bitext-tokalign.pl
#
# Copyright © 2014 Frédéric Blain <frederic.blain@lium.univ-lemans.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use utf8;
use Switch;
use List::MoreUtils qw(firstidx);

my $srcfile; my $reffile;
BEGIN {
  die "ERROR: wrong number of argument ($#ARGV instead of 2)\n
  Usage: $0 src2tgt tgt2ref > src2ref (STDOUT)\n\n" if ($#ARGV != 1);

  open $srcfile, "cat $ARGV[0] |" or die "ERROR: the source file is not reachable ($ARGV[0])\n";
  open $reffile, "cat $ARGV[1] | egrep '^ALIG:' |" or die "ERROR: the ref file is not reachable ($ARGV[1])\n";

  my $date=`date`;
  print STDERR "Alignment script is starting:\t$date";
}

END {
  my $date=`date`;
  print STDERR "The alignment is done at: $date";
}

#-------------------#
# Requirements:
# 1/ Moses word-to-word alignment between SRC & TGT         [src2tgt]
# 2/ Tercpp alignment computed between TGT & REF            [tgt2ref]
# Output:
#  SRC<=>REF alignments using the 'grow-diag-final-and' formatting (i.e: 0-0 1-1 2-2 3-..)  [src2ref]

while (my $src2tgt = <$srcfile>)
{
  chomp $src2tgt;
  my $tgt2ref = <$reffile>; chomp $tgt2ref;

  ## SRC <=> TGT alignments
  my %hashSRC2TGT = ();
  foreach my $al (split(' ',$src2tgt))
  {
    my ($src,$tgt) = ($al =~ m/(\d+)-(\d+)/);
    $hashSRC2TGT{$src}{$tgt} = 1;
  }

  ## TGT <=> REF alignments
  my (%hashTGT2REF, %hashTemp, @tabTGT, @isShift) = ();
  my $iref = 0;
  my $itgt = 0;
  my ($alignments,$nbShift,$shifts) = ($tgt2ref =~ /^ALIG:\s(.*)\s+\|\|\|\s+NbrShifts:\s(\d+)\s?(.*)$/);
  my @tabalign = split(' ',$alignments);
  for (my $i=0; $i <= $#tabalign; $i++){ $tabTGT[$i] = $i; }

  if ($nbShift)
  {
    my @tabShift = ($shifts =~ /\[.+?\]/g);

    foreach my $shift (@tabShift)
    {
      my ($start,$end,$pos) = ($shift =~ /\[(\d+),\s(\d+),\s-?\d+\/(-?\d+)\]/);
      for (my $sh_pos = $start; $sh_pos <= $end; $sh_pos++){ $isShift[$sh_pos] = $sh_pos; }

      my $size = 1+($end-$start);
      my @shift = ();
      my $idx = firstidx{ $_ == $start } @tabTGT;

      @shift = splice(@tabTGT,$idx,$size);
      if ( $pos-($end-$start) >= 0 ){ splice(@tabTGT, $pos-($end-$start), 0, @shift); }
      else { splice(@tabTGT, 0, 0, @shift); }
    } #for
  } #if nbshift

  foreach my $edType (@tabalign)
  {
    switch ($edType)
    {
      case 'A'  { $hashTGT2REF{$tabTGT[$itgt]}{$iref} = 1; $itgt++; $iref++; }
      case 'S'  { if(! exists $isShift[$itgt]){ $hashTGT2REF{$tabTGT[$itgt]}{$iref} = 1; }
                  $itgt++; $iref++;
                }
      case 'I'  { if($iref > 0){ $hashTGT2REF{$tabTGT[$itgt]}{$iref-1} = 1; }
                  $itgt++;
                }
      case 'D'  { $iref++; }
      else { print "[Error TERCpp alignment] error in editType: $edType\n"; }
    }
  } #foreach edType

  ## SRC <=> REF alignment
  my @out = ();
  foreach my $src (sort keys %hashSRC2TGT) {
    foreach my $tgt (sort keys %{$hashSRC2TGT{$src}}) {
      foreach my $ref (sort keys %{$hashTGT2REF{$tgt}}) { $out[++$#out] = $src."-".$ref; }
    }
  }
  print STDOUT "@out\n";
} #while

close $srcfile;
close $reffile;
