#!/usr/bin/awk -f

BEGIN {
# So that the awk interpreter does not attempt to read the command
# line as a list of input files.
    ARGC = 1;

# Debugging output is requested
    if(ARGV[1] != "")
    {
	debug_file = ARGV[1];
    }
    else
    {
# By doing this, we ensure that we only need to test for debugging
# output once; if it is not requested, we just write all the debugging
# statements to /dev/null
	debug_file = "/dev/null";
    }
}

# The idea here is to collect the job attributes as they are passed to
# us by the VM GAHP.  The GAHP then outputs a blank line to indicate
# that the entire classad has been sent to us.
{
    gsub(/\"/, "")
    key = $1
    # Matching value should be $3-$NR
    $1 = ""
    $2 = ""
    sub(/^  /, "")
    attrs[key] = $0
    print "Received attribute: " key "=" attrs[key] >debug_file
}

END {
	gsub(/{NAME}/, attrs["VMPARAM_VM_NAME"], attrs["VM_XML"]);
	print attrs["VM_XML"];

    exit(0);
}
