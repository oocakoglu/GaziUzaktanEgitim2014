<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Hata.aspx.cs" Inherits="GaziProje2014.Hata" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <title>Hata Oluştu</title>
    <link href="Style/css/hata.css" rel="stylesheet" type="text/css" />
    <script src="Style/js/jquery.js" type="text/javascript"></script>
    <script type="text/javascript">
        $(document).ready(function () {

            $(".ackapa").click(function () {
                $(".ackapa").toggleClass("acik");
                $(".aktif").toggleClass("isikac");
                $(this).siblings(".ackapa").removeClass("acik");
            });

        });
    </script>
</head>
<body>
    <form id="form1" runat="server">

        <div id="tasiyici">
	        <div id="avize">
		        <div class="aktif">
			        <div id="metin">
				        <p>404</p>
				        YANLIŞ YERDESİNİZ </div>
		        </div>
	        </div>
	        <div class="ackapa">
	        </div>
        </div>

    </form>
</body>
</html>
