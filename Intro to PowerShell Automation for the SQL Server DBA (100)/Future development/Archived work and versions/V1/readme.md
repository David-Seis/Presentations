# Workshop: Solving DBA Problems with PowerShell

#### <i>A course from David Seis, co-authored with Daniel Taylor and Buck Woody</i>

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/textbubble.png"> <h2>About this Workshop</h2>

Welcome to this workshop on *Solving DBA Problems with PowerShell*. In this workshop, you'll learn The basics of Powershell, as well as basic and advanced automation strategies.

The focus of this workshop is to understand how to increase the efficiency of DBA tasks.

You'll start by configuring your lab and running a few test scripts, with a focus on how to extrapolate what you have learned to create other solutions for your organization.

This [github README.MD file](https://lab.github.com/githubtraining/introduction-to-github) explains how the workshop is laid out, what you will learn, and the technologies you will use in this solution. To download this Lab to your local computer, click the **Clone or Download** button you see at the top right side of this page. [More about that process is here](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository). 

You can view all of the [courses and other workshops I have created at this link - open in a new tab to find out more.](https://github.com/David-Seis/Presentations)

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/checkmark.png"> <h3>Learning Objectives</h3>

In this workshop you'll learn:
<br>

- The Basics of Powershell Scripting
- Basic automation strategies (single-use scripts)
- Advanced automation strategies (Scheduled scripts)

Let's face it, our data estates are growing while our Database Administration teams are not. How do we handle this? I will show you how PowerShell can transform common DBA tasks into easily packaged scripts that are faster and less error prone. When you leave, you will be equipped to solve DBA issues faster and be prepared for the ever-changing database landscape. 

The goal of this workshop is to train DBAs who are new or have never used pwoershell in the basics and open up the door for increased efficiency.

The concepts and skills taught in this workshop form the starting points for:

- DBAs who are working on troubleshooting multiple SQL servers instances that have repetitive solutions.
- DBAs, to be able to create standardized implementations for various business scenarios.
- DBAs, to learn strategies for easily collecting and building reports on their SQL estate making remediation and management simpler.

<p style="border-bottom: 1px solid lightgrey;"></p>
<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/building1.png"> <h2>Business Applications of this Workshop</h2>

Businesses require their SQL Servers to be reliable, secure, and available. This workshop equips DBAs with the tools to do their job more efficiently. Ensuring SQL Servers are configured correctly, have standard tooling and maintenance, and reporting for continuous monitoring. 

Some industry examples of problems DBAs could solve with PowerShell are Migrations, Maintenance configurations, monitoring tools, to name just a few.

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/listcheck.png"> <h2>Technologies used in this Workshop</h2>

The solution includes the following technologies - although you are not limited to these, they form the basis of the workshop. At the end of the workshop you will learn how to extrapolate these components into other solutions. You will cover these at an overview level, with references to much deeper training provided.

 <table style="tr:nth-child(even) {background-color: #f2f2f2;}; text-align: left; display: table; border-collapse: collapse; border-spacing: 2px; border-color: gray;">

  <tr><th style="background-color: #1b20a1; color: white;">Technology</th> <th style="background-color: #1b20a1; color: white;">Description</th></tr>

  <tr><td><i>TODO: Technology name not owned by Microsoft that you will cover</i></td><td>TODO: Reason the student needs to learn it</td></tr>
  <tr><td>TODO: Technology name owned by Microsoft that you will cover</td><td>TODO: Reason the student needs to learn it</td></tr>

</table>

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/owl.png"> <h2>Before Taking this Workshop</h2>

You'll need a local system that you are able to install software on. The workshop demonstrations use Microsoft Windows as an operating system and all examples use Windows for the workshop. Optionally, you can use a Microsoft Azure Virtual Machine (VM) to install the software on and work with the solution.

You must have a Microsoft Azure account with the ability to create assets.

This workshop expects that you understand <TODO: Enter a brief solution for what a student should know before taking the workshop>.

If you are new to these, here are a few references you can complete prior to class:

<TODO: Enter some pre-work courses or books or whatever that the student could use to prep>
-  [Reference Name](https://url)
-  [Reference Name](https://url)
-  [Reference Name](https://url)
-  [Reference Name](https://url)


<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/bulletlist.png"> <h3>Setup</h3>

<a href="url" target="_blank">A full pre-requisites document is located here</a>. These instructions should be completed before the workshop starts, since you will not have time to cover these in class. <i>Remember to turn off any Virtual Machines from the Azure Portal when not taking the class so that you do incur charges (shutting down the machine in the VM itself is not sufficient)</i>.

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/education1.png"> <h2>Workshop Details</h2>

This workshop uses <TODO: enter main technologies used to solve the sceanrio>, with a focus on <TODO: architecture and implementation, development and use, etc>.

<table style="tr:nth-child(even) {background-color: #f2f2f2;}; text-align: left; display: table; border-collapse: collapse; border-spacing: 5px; border-color: gray;">

  <tr><td style="background-color: Cornsilk; color: black; padding: 5px 5px;">Primary Audience:</td><td style="background-color: Cornsilk; color: black; padding: 5px 5px;">TODO: Enter the technical people who will take the workshop> tasked with TODO: Enter what they are tasked to do</td></tr>
  <tr><td>Secondary Audience:</td><td> TODO: Secondary Audience</td></tr>
  <tr><td style="background-color: Cornsilk; color: black; padding: 5px 5px;">Level: </td><td style="background-color: Cornsilk; color: black; padding: 5px 5px0;"> TODO: 100, 200, 300, 400 </td></tr>
  <tr><td>Type:</td><td>TODO: In-Person, On-Line, or from github</td></tr>
  <tr><td style="background-color: Cornsilk; color: black; padding: 5px 5px;">Length: </td><td style="background-color: Cornsilk; color: black; padding: 5px 5px;">TODO: Number of hours</td></tr>

</table>

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/pinmap.png"> <h2>Related Workshops</h2>

 - [TODO: Enter any other workshops that help in this area](url)

<p style="border-bottom: 1px solid lightgrey;"></p>

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/bookpencil.png"> <h2>Workshop Modules</h2>

This is a modular workshop, and in each section, you'll learn concepts, technologies and processes to help you complete the solution.

<table style="tr:nth-child(even) {background-color: #f2f2f2;}; text-align: left; display: table; border-collapse: collapse; border-spacing: 5px; border-color: gray;">

  <tr><td style="background-color: AliceBlue; color: black;"><b>Module</b></td><td style="background-color: AliceBlue; color: black;"><b>Topics</b></td></tr>

  <tr><td><a href="url" target="_blank">TODO: 01 - Module Name </a></td><td> TODO: Module Description</td></tr>
  <tr><td style="background-color: AliceBlue; color: black;"><a href="url" target="_blank">TODO: 02 - Module 2</a> </td><td td style="background-color: AliceBlue; color: black;"> TODO: Module Description</td></tr>
  <tr><td><a href="url" target="_blank">TODO: 03 - Module Name </a></td><td> TODO: Module Description</td></tr>
  <tr><td style="background-color: AliceBlue; color: black;"><a href="url" target="_blank">TODO: 04 - Module 2</a> </td><td td style="background-color: AliceBlue; color: black;"> TODO: Module Description</td></tr>  <tr><td><a href="url" target="_blank">TODO: 05 - Module Name </a></td><td> TODO: Module Description</td></tr>
  <tr><td style="background-color: AliceBlue; color: black;"><a href="url" target="_blank">TODO: 06 - Module 2</a> </td><td td style="background-color: AliceBlue; color: black;"> TODO: Module Description</td></tr>

</table>

<p style="border-bottom: 1px solid lightgrey;"></p>

<p><img style="float: left; margin: 0px 15px 15px 0px;" src="https://raw.githubusercontent.com/microsoft/sqlworkshops/master/graphics/geopin.png"><b>Next Steps</b></p>

Next, Continue to <a href="url" target="_blank"><i> Pre-Requisites</i></a>

