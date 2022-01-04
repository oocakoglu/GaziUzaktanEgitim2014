<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DesignTest.aspx.cs" Inherits="GaziProje2014.DesignTest" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style>
            body {
	            margin:0px;
	            padding:0px;
	            font-family:verdana, arial, helvetica, sans-serif;
	            color:#333;
	            background-color:white;
	            }

            #Header {
	            margin:50px 0px 10px 0px;
	            padding:17px 0px 0px 20px;
	            /* For IE5/Win's benefit height = [correct height] + [top padding] + [top and bottom border widths] */
	            height:33px; /* 14px + 17px + 2px = 33px */
	            border-style:solid;
	            border-color:black;
	            border-width:1px 0px; /* top and bottom borders: 1px; left and right borders: 0px */
	            line-height:11px;
	            background-color:#eee;
	            voice-family: "\"}\"";
	            voice-family:inherit;
	            height:14px; /* the correct height */
	            }
            body>#Header {height:14px;}

            #Content {
	            margin:0px 50px 50px 200px;
	            padding:10px;
	            }

            #Menu {
	            position:absolute;
	            top:100px;
	            left:20px;
	            width:172px;
	            padding:10px;
	            background-color:#eee;
	            border:1px dashed #999;
	            line-height:17px;
            /* Again, the ugly brilliant hack. */
	            voice-family: "\"}\"";
	            voice-family:inherit;
	            width:150px;
	            }
            /* Again, "be nice to Opera 5". */
            body>#Menu {width:150px;}
            #footer {
                position: fixed;
                bottom: 0;
                width: 100%;
                background-color:red;
            }

    </style>

</head>
<body>
    <form id="form1" runat="server">

        <div id="Header"><a href="http://bluerobot.com/" title="BlueRobot Home">BLUEROBOT.COM</a></div>

        <div id="Content">
            ww
        </div>

        <div id="Menu">
            www
        </div>

        <div id="footer">
sss
        </div>
    </form>
</body>
</html>
