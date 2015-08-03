use File::Spec;
use File::stat;
use File::Copy;
use POSIX;
use Digest::MD5;
use Getopt::Std;

my %options;
getopts('c',\%options);


my $mediaSourceDir = $ARGV[0];

if(!-d $mediaSourceDir)
{
   print "Bad inputs: '$mediaSourceDir'\n";
   exit 1;
}

my @fileExts = ("3gp","jpg","avi","gif","tiff","jpeg","mpg","mpeg","cr2","mov");
my @dirs = ();
my @files = ();
push @dirs, $mediaSourceDir;
foreach my $dir (@dirs)
{
   if(opendir SOURCE, $dir)
   {
      while (my $dirItem = readdir SOURCE)
      {
         next if ($dirItem =~ /^\./);
         my $path = File::Spec->catfile($dir, $dirItem);
         if (-f $path) 
         {
            next if(!checkExtension($dirItem, @fileExts));

            push @files, $dirItem;
         }
      }
   }
}

my $numFiles = scalar @files;
foreach my $file (@files){
   my $rand = int(rand($numFiles));
   my $from = File::Spec->catfile($mediaSourceDir,$file);
   my $to = File::Spec->catfile($mediaSourceDir,"${rand}_$file");
   moveOrCopy($from, $to);
}
#print "FILES:",join(',',@files),"\n",
#"DIRS:",join(',',@dirs),"\n";

sub moveOrCopy
{
   my $from = shift;
   my $to = shift;

   my $type;
   
   if($options{c})
   {
      $type = "copying";
      copy $from, $to;
   }
   else
   {
      $type = "moving";
      move $from, $to;
   }
   print "$type '$from' to '$to'\n";
}
sub buildRoot
{
   my $path = shift;
   my $root = shift;
   my $stat = stat($path);
   if(!$stat)
   {
      print "Couldn't stat $path: $!\n";
      return;
   }
   
   my $yDir = File::Spec->catfile($root,POSIX::strftime("%Y",localtime $stat->mtime));
   my $mDir = File::Spec->catfile($yDir,POSIX::strftime("%Y-%m",localtime $stat->mtime));
   my $dDir = File::Spec->catfile($mDir,POSIX::strftime("%Y-%m-%d",localtime $stat->mtime));
   
   
   
   mkdir $yDir if(!-e $yDir);
   mkdir $mDir if(!-e $mDir);
   mkdir $dDir if(!-e $dDir);
   
   return $dDir;
}

sub checkExtension
{
   my $path = shift;
   my @valids = @_;
   
   my $ext = $path;
   $ext =~ s/^.*?\.([^\.]*?)$/$1/;
   if($ext ne "")
   {
      for $valid (@valids)
      {
         if($ext =~ /$valid/i)
         {
            return 1;
         }
      }
   }
   return 0;
}
