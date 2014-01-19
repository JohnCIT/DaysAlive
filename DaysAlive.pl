#!/usr/bin/perl 

use strict;
use warnings;

use CGI::Pretty ':standard';
use CGI::Carp qw(fatalsToBrowser);

# Debug file
#open(DEBUG, ">", "debug.txt") or die "$!\n";


# Print the HTML header
print header;

# The site name
my $site = 'How many days have you been alive?';

# Form titles
my @formTitles=qw/Login EnterDates Comments/;

# Buttons
my $goStart  = 'Start';
my $login    = 'Login';
my $calcDays = 'Calculate life';
my $logout   = 'Logout';
my $comment  = 'Comments';
my $submitComment  = 'Submit Comment';
my $backToCalc     = 'Back to Calculate Days';

# Check box names
my $countBirth = "calculateBirth";
my $countSecs  = "calcSecs";
my $countMins  = "calcMins";
my $countHours = "calcHours";

# The beginning of the font to display red
my $red = "<font color=red>";

# Find out what button was pressed
my $buttonPressed = param('next') || $goStart;

# Pass in the button pressed so the controller can decide what for to build
&controller($buttonPressed);


# Close the debug file
#close (DEBUG);




#################################### Sub routines #############################
###############################################################################








################################## Controller stuff ###########################
###############################################################################

# The controller
# Detects what button was pressed and reacts accordingly
sub controller {
    
    my $previousButton = shift; # The previous button
        
    # Where the warning messages will be held
    my @warnings = ();
    
    # Hash where the colours of the html elements will be stored
    my %htmlColour = ();
    
    # Check if the this is the first run, If not generate the views based on the result of checking and previous button
    if ($previousButton =~ /^$goStart$/) {
        &buildForm(0, \@warnings, \%htmlColour);
    }
    elsif ($previousButton =~ /^$login$/) {
        if (&isUserNameAndPasswordCorrect(\@warnings, \%htmlColour) ) {
            &buildForm(1, \@warnings, \%htmlColour);
        }
        else {
            &buildForm(0, \@warnings, \%htmlColour);
        }
    }   
    elsif ($previousButton =~ /^$calcDays$/ ) {
        &checkDateIsCorrect(\@warnings, \%htmlColour);
        &buildForm(1, \@warnings, \%htmlColour);        
    }
    elsif ($previousButton =~ /^$logout$/) { 
        &buildForm(0, \@warnings, \%htmlColour);
    }
    elsif ($previousButton =~ /^$comment$/) {
        &buildForm(2, \@warnings, \%htmlColour);
    }
    elsif ($previousButton =~ /^$backToCalc$/) {
        &buildForm(1, \@warnings, \%htmlColour);
    }
    elsif ($previousButton =~ /^$submitComment$/) {
        if (&doesCommentHaveContent(\@warnings, \%htmlColour)) {
            &saveComment();         # Save the comment
            &resetCommentView();    # Clear the fields
        }
        &buildForm(2, \@warnings, \%htmlColour);
        
    }
        
}









################################# View stuff ##################################
###############################################################################

# Receives the reference to the array to display messages and a number deciding which view to build
sub buildForm() {
    my $form    = shift;
    my $warnRef = shift;
    my $htmlCol = shift;
        
    if ($form == 0) {
        &printHeader("$site: $formTitles[0]");  # Prints the HTML header. This includes the opening tag and the h1 section
        &buildStartView($warnRef, $htmlCol);    # Builds the rest of the view and the and the error messages to display
    }
    elsif ($form == 1) {
        &printHeader("$site: $formTitles[1]");
        &buildSecondView($warnRef, $htmlCol);
    }
    elsif ($form == 2) {
        &printHeader("$site: $formTitles[2]");
        &buildCommentView($warnRef, $htmlCol);
    }
}






# Build the starting view
sub buildStartView {    
    my $warnRef     = shift;
    my $htmlColRef  = shift;
    
    # Print error messages
    if ($warnRef) {
        foreach my $warn (@$warnRef) {
            print $warn, p;
        }
    }
    
    # Start the form
    print start_form(-method=>"POST");
    
    # print the content
    print table({-cellpadding=>'5', -cellspacing=>'5'},
                Tr({-align=>'LEFT', -valign=>'MIDDLE'}, 
                [
                    td(["$$htmlColRef{'userName'}Username: *", textfield(-name=>'userName',      -tabindex=>1)]),
                    td(["$$htmlColRef{'password'}Password: *", password_field(-name=>'password', -tabindex=>2)]),
                    td(['', &makeSubmitButton($login, 100)]), # Make the button
                ])
                );  
    
    # End the form
    print end_form; 
    
    # Print the footer
    &printFooter($site, "NoOne");
}


# Build the second view
sub buildSecondView {
    my $warnRef     = shift;
    my $htmlColRef  = shift;
    
    my @mDays;
    my @months;
    my @years;
    
    my $days = 0;
    
    #Get the current year to work with
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); #Gets the local time and stores it in the variables
    $year += 1900; #Gets the correct year. what is returned is the years that passed since 1900  so adding 1900 fixes that
    
    # Prepare the widgets to be displayed
    # Days
    for (my $i=1; $i<13; $i++) {
        push (@months, $i);
    }
    
    #Months
    for (my $i=1; $i<32; $i++) { 
        push (@mDays, $i);
    }
    
    #Years
    for (my $i=$year; $i>1800; $i--) { 
        push (@years, $i);
    }
    
    # Print the error messages
    if ($warnRef) {
        foreach my $warn (@$warnRef) {
            print $warn, p;
        }
    }
    
    # Start the form
    print start_form(-method=>"GET");
    
    print "Enter your birthday!", br;
    
    # Print the enter the users birthday section
    print "$$htmlColRef{'day'}Day</font>",   popup_menu(-name=>'days',  -values=>\@mDays);
    print "Month",                           popup_menu(-name=>'months', -values=>\@months);
    print "$$htmlColRef{'year'}Year</font>", popup_menu(-name=>'year',  -values=>\@years);
    
    # The division out put
    print br, br, br, "Enter the current day!", br;
    
    # Print the current day selection
    print "$$htmlColRef{'cDay'}Day</font>",   popup_menu(-name=>'Cdays',     -values=>\@mDays);
    print "Month",                            popup_menu(-name=>'Cmonths', -values=>\@months);
    print "$$htmlColRef{'cYear'}Year</font>", popup_menu(-name=>'Cyear',     -values=>\@years), br, br;
    
    # Print the check boxes
    print checkbox(-name=>$countBirth, -checked=>"true", -value=>$countBirth, -label=>'Include Current Day?'),  br; 
    print checkbox(-name=>$countSecs,  -checked=>0, -value=>$countSecs,  -label=>'Display Seconds?'),           br;
    print checkbox(-name=>$countMins,  -checked=>0, -value=>$countMins,  -label=>'Display Minutes?'),           br; 
    print checkbox(-name=>$countHours, -checked=>0, -value=>$countHours, -label=>'Display Hours?'),             br; 
    
    
    
    # Get the users date
    my $year   = param('year');
    my $month  = param('months');
    my $day    = param('days');
    my $cYear  = param('Cyear');
    my $cMonth = param('Cmonths');
    my $cDays  = param('Cdays');
        
    # Get how many days the user has been alive
    $days = &getDaysAliveMain($year, $month, $day, $cYear, $cMonth, $cDays);
    
    # Check if the count current day is selected and add one
    if (param($countBirth)) {
        $days ++; 
    }
    
    # Check if there are any errors, if not display the days alive
    if (!@$warnRef) {
        # Work out secs, mins, hours
        my $hours = $days  * 24;
        my $mins  = $hours * 60;
        my $secs  = $mins  * 60;
            
        # Print the content
        print br, br, "You have lived for ", $days, " days!", br;
        
        # Check if seconds is selected. If so display seconds
        if (param($countSecs)) {
            print "You lived $secs seconds", br;
        }
        
        # Check if minutes is selected, If so display minutes
        if (param($countMins)) {
            print "You have lived $mins minutes", br;
        }
        
        # Check if the hours was selected, if so display the hours alive
        if (param($countHours)) {
            print "You have lived $hours hours", br;
        }
    }
    else {
        print br;
        print "Correct errors to see result", br;
    }
    
    # Print the buttons
    print br, &makeSubmitButton($calcDays,  100);
    print br, &makeSubmitButton($comment,   100);
    print br, &makeSubmitButton($logout,    100);
    
    
    
    # End the form
    print end_form;     
    
    # Print the footer
    &printFooter($site, "NoOne");
}


# Print the HTML header
sub printHeader {
    my $site = shift;   # Get the title
    
    # Makes the basic header with the site title
    print start_html($site);
    
    # Give the h1 title
    print h1($site);
    
    # Draw the line
    print hr;   
}


# Make a button with the title passed in
sub makeSubmitButton {
    my $buttonCaption = shift;
    my $tab = shift;
    
    return submit(-name=>'next', -value=>$buttonCaption, -tabindex=>$tab);
}


# Make the page footer
sub printFooter {
    my $site    = shift;    # The site name
    my $contact = shift;    # The contact address
    
    print hr, p, $site, " Contact: "; # Prints the lins at the botton of the page, a paragraph tag and the site name
    print a({href=>"mailto:$contact?subject=$site"}, "WebMaster"); # Mail to tag, allows the user to click on the link and it will open their email client with the said address entered
    print end_html; # Close the html tag, end of site
}



sub buildCommentView {
    my $warnRef     = shift;
    my $htmlColRef  = shift;
    
    # Make the array to hold the comments
    my @comments = ();
    
    # Read in the comments
    &readComments(\@comments);
    
    print ("<b>Comments:</b>");
    print (br, br);
    
    # Print the comments already stored
    if (@comments) {
        my $index = 0;
    
        foreach my $comment (@comments) {
            if ($index % 2 == 0) {
                print "<b>$comment: </b> ";
            }
            else {
                print $comment, p;
            }
            
            $index ++;
        }
    }
    
    print (br, br);
    print ("<b>Have your say!</b>", br, br);
    
    # Print the error messages
    if ($warnRef) {
        foreach my $warn (@$warnRef) {
            print $warn, p;
        }
    }
    
    # Start the form
    print start_form(-method=>"POST"); # If get is used refreshing the page causes duplicate posts
    
    # Ask the user for there name
    print ("$$htmlColRef{'name'}Name *</font>", br);
    
    # Make the text field
    print textfield(-name => 'name', -size => 30), br, br; 
    
    # Ask the user for their comment
    print ("$$htmlColRef{'comment'}Comment *</font>", br);
        
    # Make the text area
    print textarea(-name=>'comment',-rows=>10,-columns=>50), br;
    
    # Print the buttons
    print br, &makeSubmitButton($submitComment, 100);
    print br, &makeSubmitButton($backToCalc,    100);
    print br, &makeSubmitButton($logout,        100);
    
    # End the form
    print end_form; 
    
    # Print the footer
    &printFooter($site, "NoOne");
}




################################ Model stuff ##################################
###############################################################################



# Resets the comment view (Clear fields)
sub resetCommentView {
    param('name', "");
    param('comment', "");
}


# Checks if the comment has content
sub doesCommentHaveContent {
    my $warnRef    = shift;
    my $htmlColRef = shift;
    
    my $hasContent = 1;
    
    # Get inputs
    my $name    = param('name');
    my $comment = param('comment');
    
    # Make sure the entered data has content
    if ($name =~ /^$/) {
        $hasContent = 0;
        push (@$warnRef, "$red You must enter a name</font>");
        $htmlColRef->{"name"} = $red;
    }
    
    if  ($comment =~ /^$/) {
        $hasContent = 0;
        push (@$warnRef, "$red You must enter a Comment</font>");
        $htmlColRef->{"comment"} = $red;
    }
    
    return $hasContent;

}


# Save the users comment
sub saveComment {
    
    my $name = param('name');
    
    
    # Get all the text from the text field and sort it into one variable to save
    my $comment = param('comment');
    my @allLines = $comment =~ /(.+)(?:\n|$)/g;
    
    # Where the comment will be saved
    my $commentToSave;
    
    # Append to the variable for saving
    foreach my $indCom (@allLines) { 
        $commentToSave .= $indCom; 
    }
    
    my $outfile = "comments.txt";
    
    open(OUTFILE, ">>", $outfile) or die "There has been a error on our side, sorry";
    
    print OUTFILE $name, "\n";  
    print OUTFILE $commentToSave, "\n";
    
    close (OUTFILE);
    
}



# Read in the comments and names
sub readComments {
    my $arrayRef = shift;
    
    my $infile = "comments.txt";
    
    open(INFILE, "<", $infile) or die "There has been a error on our side, sorry";
    
    while (<INFILE>) {
        my $input  = $_;
        
        chomp($input);
        
        # Add the comment or name to the array
        push(@$arrayRef, $input);       
    }
    
    # Close the file
    close (INFILE);
    
}




# Read in the usernames and password and store them in a hash
sub readAndStoreUserDetails { 
    my %hash = @_;

    my $infile = "userlist.txt";
    
    open(INFILE, "<", $infile) or die "There has been a error on our side, sorry";

    while (<INFILE>) {
        my $userName  = $_;
        my $password  = <INFILE>;

        chomp($userName, $password);
        
        # Add items to the hash
        $hash{$userName} = $password;
    }   
    close (INFILE);
    
    return %hash;
}


# Check the user name and password
sub isUserNameAndPasswordCorrect {
    my $warnRef    = shift;
    my $htmlColRef = shift;
    
    # Read in the the details
    my %userNames = (); 
    %userNames = readAndStoreUserDetails(%userNames);
    
    my $userName = param('userName');
    my $password = param('password');
    
    # Put the message into the array to display later that they must have a input The regex matches a empty string. Probably overkill
    if ($userName =~ /^$/) {
        push (@$warnRef, "$red The username must have input.</font>");
        $htmlColRef->{"userName"} = $red;   # prepare the colour
    }
    
    # Put the message into the array to display later that they must have a input. Also the colour
    if ($password =~ /^$/) {
        push (@$warnRef, "$red The password must have input.</font>");
        $htmlColRef->{"password"} = $red;
    }   
    
    # Check if the key exists. If so then check the password
    if (exists $userNames{$userName}) {
        
        # Get the password corresponding to the user name and test it
        my $UserNamePassword = $userNames{$userName};
        
        # Check the password
        if ($UserNamePassword eq $password) { 
            return 1; 
        }
        else {
            # Tell the user the password is incorrect
            push (@$warnRef, "$red The password is incorrect</font>");
            $htmlColRef->{"password"} = $red;
        }
    }
    else {
        # Tell the user the pass word or user name is correct
        push (@$warnRef, "$red The user name is incorrect</font>");
        $htmlColRef->{"userName"} = $red;
    }
    
    
    
    return 0;   
}


# Check the dates are correct 
sub checkDateIsCorrect {
    my $warnRef     = shift;
    my $htmlColRef  = shift;
            
    # Get the users date
    my $birthYear   = param('year');
    my $birthMonth  = param('months');
    my $birthDay    = param('days');
    my $cYear       = param('Cyear');
    my $cMonth      = param('Cmonths');
    my $cDays       = param('Cdays');
    
    # The date valid score
    my $isDateValid = 1;
      
    # As dates are one behind minus one
    $birthMonth --;
    $cMonth --;
    
    # Check if the date is before the current date
    if (!&checkBirthdayIsBeforeCurrentDate($birthYear, $birthMonth, $birthDay, $cYear, $cMonth, $cDays) ) {
        
        # Add one so the error message is correct
        $birthMonth ++;
        $cMonth ++;
        
        push (@$warnRef, "$red The birth date is after ($birthDay/$birthMonth/$birthYear) the current date ($cDays/$cMonth/$cYear)
              </br> The birth year ($birthYear) is after the current year ($cYear)
              </br> You are yet to be born!</font>");
        $isDateValid = 0;
        
        # Prepare colours
        $htmlColRef->{"day"}   = $red;
        $htmlColRef->{"cDay"}  = $red;
        $htmlColRef->{"year"}  = $red;
        $htmlColRef->{"cYear"} = $red;
        
        # As dates are one behind minus one
        $birthMonth --;
        $cMonth --;
    }
    
    # Check the dates are sensible
    if (!&isMonthDaysCorrect($birthYear, $birthMonth, $birthDay, $warnRef, $htmlColRef)) {
        $isDateValid = 0;
    }
    
    # Check the dates are sensible
    if (!&isCurrentMonthDaysCorrect($cYear, $cMonth, $cDays, $warnRef, $htmlColRef)) {
        $isDateValid = 0;
    }
    
    return $isDateValid;
}


# Ensure the month selected and the days are sensible
sub isMonthDaysCorrect {
    my $birthYear  = shift;
    my $birthMonth = shift;
    my $birthDay   = shift;
    my $warnRef    = shift;
    my $htmlColRef = shift;
    
    my $daysInMonth = &getDaysInMonth($birthMonth);
    
    my $isCorrect = 1;
        
    if (&checkForLeapYear($birthYear) && $birthMonth == 1) {
        $daysInMonth = 29;
    }
    
    if ($birthDay > $daysInMonth) {
        $isCorrect = 0;
        push (@$warnRef, "$red Birth day number must be (1 - $daysInMonth))</font>");
        $htmlColRef->{"day"} = $red;
    }
    
    return $isCorrect;  
}


# Ensure the month selected and the days are sensible
sub isCurrentMonthDaysCorrect {
    my $birthYear  = shift;
    my $birthMonth = shift;
    my $birthDay   = shift;
    my $warnRef    = shift;
    my $htmlColRef = shift;
    
    my $daysInMonth = &getDaysInMonth($birthMonth);
    
    my $isCorrect = 1;
        
    if (&checkForLeapYear($birthYear) && $birthMonth == 1) {
        $daysInMonth = 29;
    }
    
    if ($birthDay > $daysInMonth) {
        $isCorrect = 0;
        push (@$warnRef, "$red Current day number must be (1 - $daysInMonth))</font>");
        $htmlColRef->{"cDay"} = $red;
    }
    
    return $isCorrect;  
}




################## Days alive section #########################################
###############################################################################

sub getDaysAliveMain { 
    
    my $birthYear    = shift;
    my $birthMonth   = shift;
    my $birthDay     = shift;
    my $currentYear  = shift;
    my $currentMonth = shift;
    my $currentday   = shift;
    
    #Variables
    my $days = 0; #Where the amount of days will be held
        
    #The first month starts at zero, The user wont know this. So it must be consistent
    $birthMonth     -= 1;
    $currentMonth   -= 1;

    #Get Days of all full years
    $days += &fullYears($birthYear, $currentYear);
    #Get the full month days
    $days += &getFullMonths($birthMonth, $currentMonth); 
    #Get the days in the month
    $days += &getDaysLeftInCurrentMonth($birthDay, $currentday);
    #Add any leap years
    $days += &checkUserForLeapYear($birthYear, $currentYear); 
    #Check if the birthYear is a leap year and the birthDay is on/before the 29th Feb
    $days += &checkBirthYearForLeapYear($birthYear, $birthMonth, $birthDay); 
    #Check if the current year is a leap year and the current date is on/after the 29th Feb
    $days += &checkCurrentYearForLeapYear($currentYear, $currentMonth, $currentday);
    
    
    #Display the answer
    return $days;
}






###############################################################################
##### Sub routines ############################################################
###############################################################################





#Check the current year is a leap year an if the current date is on or after the 29th Feb
sub checkCurrentYearForLeapYear
{
    my $currentYear  = shift;
    my $currentMonth = shift;
    my $CurrentDay   = shift;
    
    if (checkForLeapYear($currentYear))
    {
        if ($currentMonth >= 1)
        {
            if ($CurrentDay == 29)
            {
                return 1;
            }
        }
    }
    else
    {
        return 0;
    }
}



#Checks the birth year and date for leap year
sub checkBirthYearForLeapYear
{
    my $birthYear  = shift;
    my $birthMonth = shift;
    my $birthDay   = shift;
    
    if (checkForLeapYear($birthYear))
    {
        if ($birthMonth <= 1)
        {
            if ($birthDay <= 29)
            {
                return 1;
            }
        }
    }
    else
    {
        return 0;
    }
}




#Adds the total sum of all the leap years the user has lived through
sub checkUserForLeapYear
{
    my $birthYear   = shift;
    my $currentYear = shift;
    
    my $days;
    
    while ($birthYear < $currentYear)
    {
        $days += &checkForLeapYear($birthYear);
        $birthYear++;
    }
    
    return $days;
}




#Checks the year passed in for a leap year
sub checkForLeapYear
{
    my $year = shift;
    
    if ($year%400 == 0) #If the year is 1600, 2000 or so it is a leap year
    {
        return 1;
    }
    elsif ($year%100 == 0) #Catches the years where no leap year occurs E.G 1700, 1800
    {
        return 0;
    }
    elsif ($year%4 == 0) #Any year left that is divisable by 4 is a leap year
    {
        return 1;
    }
    else #Anything left is not a leap year
    {
        return 0;
    }
}





#The current month days
sub getDaysLeftInCurrentMonth
{
    my $birthDay   = shift;
    my $currentDay = shift;
    
    return $currentDay - $birthDay; #Return a minus value on this one as the birthday has passed the current day
}





#Adds on the full months of the year
sub getFullMonths
{
    my $birthMonth   = shift;
    my $currentMonth = shift;
    
    my $sumOfDays = 0;
    
    if ($currentMonth > $birthMonth)
    {
        while ($currentMonth > $birthMonth) 
        {
            $sumOfDays += &getDaysInMonth($birthMonth);
            $birthMonth ++;
        }
    }
    else
    {
        while ($birthMonth > $currentMonth)
        {
           $sumOfDays -= &getDaysInMonth($birthMonth);
           $birthMonth --;
        }
    }
    
    return $sumOfDays   
}





#Returns the amount of days in a month
sub getDaysInMonth
{
    my $month = shift;
    
    
    if ($month == 1)
    {
        return 28;
    }
    elsif ($month == 8 || $month == 3 || $month == 5 || $month == 10)
    {
        return 30;
    }
    else
    {
        return 31;
    }
}





#Check if it is the users birthday, If so it will wish them a greeting
sub checkIfBirthday
{
    #Organize inputs
    my $birthMonth      = shift;
    my $birthDay        = shift;
    my $currentMonth    = shift;
    my $currentDay      = shift;
    
    if($birthMonth == $currentMonth && $birthDay == $currentDay)
    {
        print "Happy birthday!";
    }
}





#Check if the birthday is before the the current day if not return false
sub checkBirthdayIsBeforeCurrentDate
{
    #Organize inputs
    my $birthYear       = shift;
    my $birthMonth      = shift;
    my $birthDay        = shift;
    my $currentYear     = shift;
    my $currentMonth    = shift;
    my $currentDay      = shift;

    #now check the birthday is before the current date
    if ($currentYear > $birthYear) {
        return 1;
    }
    
    #Check if the years are equal, if so run some checks to ensure the birth is before the curentDay
    if ($currentYear == $birthYear)
    {
        if ($currentMonth > $birthMonth)
        {
            return 1;
        }
        elsif ($currentMonth == $birthMonth)
        {
            if ($currentDay > $birthDay)
            {
                return 1;
            }
            elsif ($birthDay == $currentDay) {
                return 1;
            }
            else
            {
                return 0;
            }
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }   
}





#Days of all full years
sub fullYears
{
    my $birthYear   = shift;
    my $currentYear = shift;
    
    return ($currentYear - $birthYear) * 365;
}



#Check there is a digit in the input
sub isinteger
{
    my $n = shift; #get argument
    
    if ($n =~ /^-?\d+$/ ) #if $n is an integer
    {
        return 1; 
    }
    else 
    { 
        return 0;
    }
}







