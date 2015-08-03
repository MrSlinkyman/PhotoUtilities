use File::Spec;
use File::stat;
use File::Copy;
use POSIX;
use Digest::MD5;
use Getopt::Std;

my %options;
getopts('c',\%options);


my $mediaSourceDir = $ARGV[0];
my $mediaRootDir = $ARGV[1];

if(!-d $mediaSourceDir || !-d $mediaRootDir)
{
   print "Bad inputs: '$mediaSourceDir', '$mediaRootDir'\n";
   exit 1;
}

print "Starting: $mediaSourceDir -> $mediaRootDir\n";

my @fileExts = ("3gp","jpg","avi","gif","tiff","jpeg","mpg","mpeg","cr2","mov");
my @dirs = ();
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
            my $root = buildRoot($path, $mediaRootDir);
            my $rootFile = File::Spec->catfile($root,$dirItem);
            if(-e $rootFile)
            {
               if(open(FILE, $path))
               {
                  binmode(FILE);
                  my $md5p = Digest::MD5->new->addfile(*FILE)->hexdigest;
                  close FILE;
                  if(open ROOT, $rootFile)
                  {
                     binmode(ROOT);
                     my $md5r = Digest::MD5->new->addfile(*ROOT)->hexdigest;
                     close ROOT;
                     if($md5p ne $md5r)
                     {
                        my $temp = $rootFile;
                        $temp =~ s/\.([^\.]*)$/-1.$1/;
                        print "WARNING: $rootFile exists and is not the same as $path, renaming to '$temp'\n";
                        moveOrCopy($path, $temp);
                     }
                     else
                     {
                        print "WARNING: $rootFile and $path are the same file, no action taken\n";
                     }
                  }
                  else
                  {
                     print STDERR "ERROR: could not open $rootFile:$!","\n";
                  }
               }
               else
               {
                  print STDERR "ERROR: could not open $path:$!", "\n";
               }
            }
            else
            {
               moveOrCopy($path, $rootFile);
            }
         }
         elsif (-d _)
         {
            print "DIR:",$path,"\n";
            push @dirs, $path;
         }
         else
         {
            print "Couldn't stat $path\n";
         }
      }
      closedir SOURCE;
   }
   else
   {
      print "NO GO on $dir:",$!;
   }
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
