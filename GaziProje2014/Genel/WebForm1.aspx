<%@ Page Title="" Language="C#" MasterPageFile="~/PublicSite.Master" AutoEventWireup="true" CodeBehind="WebForm1.aspx.cs" Inherits="GaziProje2014.Genel.WebForm1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
    <script>
    $(document).ready(function() {
        $('.kare').hide();	
    });
    function goster()
	    {
		    $('.kare').slideToggle(1000);		
	    }
    </script>


    <div runat="server" class="OtherFile">
         
           <video width="100%" height="100%" controls>
              <source src="/Dokumanlar/OmerFarukOcakoglu/AppBuilder.mp4" type="video/mp4">            
              Your browser does not support the video tag.
          </video> 

<%--        <object width="100%" height="100%" data="/Dokumanlar/OmerFarukOcakoglu/ödev 3.pdf">
        </object>--%>

    </div>

    <div class="solAltKose">
        <asp:imagebutton runat="server" Id="btnInformation" ImageUrl="~/Style/information.png" OnClientClick="goster(); return false;"></asp:imagebutton>
    </div>


    <div class="kare">
            Yalın - Ellerine Saglik Video Klibi<br />
            Ellerine sağlık, hadi durma kutla bu zafer senin <br />
            Yüreğine sağlık, yalan dünyanda tek safirin<br /> 
            Onu kaybetme, onu kirletme, hırsınla süsleme(x2)<br /> 
            <br />
    <%--        Hadi seni sevdim diyelim bir daha, <br />
            Gözümü karartıp yeniden taptığımda <br />
            Değişecek misin söyle, değişebilecek misin zalim?<br /> 
            Değişecek misin söyle, değişebilecek misin zalim?<br /> 
            <br />
            Zalim oyun bozan, sen de bu büyü de yalan gelip de bir tanem olmaya ne hakkın var? <br />
            Zalim oyun bozan, sen de bu büyü de yalan gelip de bu canda hükmetmeye ne hakkın var? <br />
            Gelip de birtanem olmaya ne hakkın var?<br /> 
            Ellerine sağlık, hadi durma kutla bu zafer senin <br />
            Yüreğine sağlık, yalan dünyanda tek safirin <br />
            Onu kaybetme, onu kirletme, hırsınla süsleme <br />--%>
            <br />
            Hadi seni sevdim diyelim bir daha<br />
            Gözümü karartıp yeniden taptığımda <br />
            Değişecek misin söyle, değişebilecek misin zalim?<br /> 
            Değişecek misin söyle, değişebilecek misin zalim? <br />
            <br />
            Zalim oyun bozan, sen de bu büyü de yalan gelip de bir tanem olmaya ne hakkın var?<br /> 
            Zalim oyun bozan, sen de bu büyü de yalan gelip de bu canda hükmetmeye ne hakkın var? <br />
            bir tanem olmaya ne hakkın var?
        <br />
        <asp:imagebutton runat="server" Id="btnClose" ImageUrl="~/Style/Closebutton.png" OnClientClick="goster(); return false;"></asp:imagebutton>
    </div>    


<%--        Yalın - Ellerine Saglik Video Klibi
        Ellerine sağlık, hadi durma kutla bu zafer senin 
        Yüreğine sağlık, yalan dünyanda tek safirin 
        Onu kaybetme, onu kirletme, hırsınla süsleme(x2) 

        Hadi seni sevdim diyelim bir daha, 
        Gözümü karartıp yeniden taptığımda 
        Değişecek misin söyle, değişebilecek misin zalim? 
        Değişecek misin söyle, değişebilecek misin zalim? 

        Zalim oyun bozan, sen de bu büyü de yalan gelip de bir tanem olmaya ne hakkın var? 
        Zalim oyun bozan, sen de bu büyü de yalan gelip de bu canda hükmetmeye ne hakkın var? 
        Gelip de birtanem olmaya ne hakkın var? 
        Ellerine sağlık, hadi durma kutla bu zafer senin 
        Yüreğine sağlık, yalan dünyanda tek safirin 
        Onu kaybetme, onu kirletme, hırsınla süsleme 

        Hadi seni sevdim diyelim bir daha 
        Gözümü karartıp yeniden taptığımda 
        Değişecek misin söyle, değişebilecek misin zalim? 
        Değişecek misin söyle, değişebilecek misin zalim? 

        Zalim oyun bozan, sen de bu büyü de yalan gelip de bir tanem olmaya ne hakkın var? 
        Zalim oyun bozan, sen de bu büyü de yalan gelip de bu canda hükmetmeye ne hakkın var? 
        bir tanem olmaya ne hakkın var?--%>




<%--   <div runat="server" class="test" id="pnlIcerikContent">           
   </div>--%>


</asp:Content>
