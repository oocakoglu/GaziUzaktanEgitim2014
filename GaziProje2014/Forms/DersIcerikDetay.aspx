<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="DersIcerikDetay.aspx.cs" Inherits="GaziProje2014.Forms.DersIcerikDetay" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <style>  
        .IcerikGovde {
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 40px;      
            overflow: scroll;
            overflow-x:hidden; 
            z-index: 1;             
        }

        .IcerikGovdeGolge {
            position: absolute;
            top: 0px;
            left: 0px;
            right: 0px;
            bottom: 40px;      
            overflow: hidden;

            background-color:white;
            opacity: 0.7; 
            filter: alpha(opacity=70);             
                        
        }


        .FormTablo{
            padding:5px;
            vertical-align:bottom;
        }



    </style> 

    <script type="text/javascript">
        function toggleTextBox() {
            var radiobuttonList = document.getElementById('<%= rbList.ClientID %>');
            var options = radiobuttonList.getElementsByTagName('input');
            var pageView = $find("<%= dersMultiPage.ClientID %>");

            for (var i = 0; i < options.length; i++) {
                if (options[i].checked)
                    pageView.set_selectedIndex(i);
            }

        }


        function OnClientItemSelected(sender, args) {
            var textbox = $find("<%= fileName.ClientID %>");
            //textbox.set_value(args.get_item().get_name());
            textbox.set_value(args.get_item().get_path());

        }
    </script>


    <div class="IcerikGovde">
          
        <table style="width:100%;">
            <tr>
                <td>
<%--                    <fieldset style="padding:5px;">
                        <legend>İçerik Genel Bilgileri</legend>--%>

                        <table class="FormTablo">
                            <tr class="FormTablo">
                                <td class="FormTablo">Ders Adı :</td>
                                <td>
                                   <telerik:RadDropDownList ID="rdDersler" runat="server" Width="300" OnItemSelected="RadDropDownList1_ItemSelected" OnSelectedIndexChanged="rdDersler_SelectedIndexChanged" AutoPostBack="true">
                                   </telerik:RadDropDownList>  
                                </td> 
                            </tr>
                            <tr  class="FormTablo">
                                <td class="FormTablo">Üst Başlık :</td>
                                <td>
                                    <telerik:RadDropDownTree runat="server" ID="rdcbUstBaslik"  Width="250px"
                                        DefaultMessage="Üst Konu Varsa Seçiniz">
                                        <DropDownSettings Height="240px" CloseDropDownOnSelection="true" />
                                    </telerik:RadDropDownTree>
                                    <asp:CheckBox ID="chkUstKonu" runat="server" AutoPostBack="true" OnCheckedChanged="chkUstKonu_CheckedChanged" Text="Üst Konu Yok" />                  
                                </td>
                            </tr>
                            <tr  class="FormTablo">
                                <td class="FormTablo">Konu Adı :</td>
                                <td class="auto-style1">
                                    <telerik:RadTextBox ID="txtKonuAdi" runat="server" Width="300"></telerik:RadTextBox>
                                    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                    <asp:Label ID="Label1" runat="server" Text="Sıra"></asp:Label>
                                    <telerik:RadTextBox ID="txtSira" runat="server" Width="50"></telerik:RadTextBox>
                                </td>
                            </tr>            
                            <tr  class="FormTablo">
                                <td class="FormTablo" colspan="2">
                                    <asp:RadioButtonList ID="rbList" runat="server" RepeatColumns="3" onclick="toggleTextBox();" >
                                        <asp:ListItem Selected="True" Value="1">İçerik Yaz</asp:ListItem>
                                        <asp:ListItem  Value="2">Dosyadan Seç</asp:ListItem>
                                        <asp:ListItem Value="3">Bir Kaynaktan Embed Et</asp:ListItem>
                                    </asp:RadioButtonList>
                                </td>
                            </tr>    
                        </table>
<%--                    </fieldset>--%>
                </td>
                <td style="vertical-align:top; text-align:right;">
                    <fieldset style="text-align:left;">
                        <legend>Dışarıya Açık İçerik</legend>
                           <table style="width:100%;">
                               <tr>
                                   <td>
                                       <asp:CheckBox ID="chkPublic" runat="server" Text="Dışarıya Açık" /> 
                                   </td>
                               </tr>
                               <tr>
                                   <td>
                                       http://uegitim.com/Genel/
                                   </td>
                               </tr>
                               <tr>
                                   <td>
                                       <telerik:RadTextBox ID="txtDisUrlName" runat="server" Width="100%" TextMode="MultiLine"></telerik:RadTextBox>
                                   </td>
                               </tr>
                               <tr>
                                   <td>
                                       <telerik:RadButton ID="btnDenetle" runat="server" Text="Denetle" OnClick="btnDenetle_Click"></telerik:RadButton>
                                   </td>
                               </tr>
                           </table>                             
                    </fieldset>
                </td>
            </tr>
        </table>






        <telerik:RadMultiPage ID="dersMultiPage" runat="server" SelectedIndex="0">
            <telerik:RadPageView ID="RadPageView1" runat="server">

                  <telerik:RadEditor ID="rdDersEditor" runat="server" Width="100%" Height="500px">
                     <CssFiles>
                         <telerik:EditorCssFile Value="../Style/css/Editors.css" />
                     </CssFiles>
                  </telerik:RadEditor>

            </telerik:RadPageView>
            <telerik:RadPageView ID="RadPageView2" runat="server">
                <table>
                    <tr>
                        <td>
                            <label for="fileName">Seçilen Dosya:</label>
                        </td>
                        <td>
                          <telerik:RadTextBox ID="fileName" runat="server" Width="350px">
                          </telerik:RadTextBox>
                        </td>
                        <td>
                           <telerik:RadButton ID="RadButton1" runat="server" Text="RadButton" OnClick="btnDosyaSec_Click"></telerik:RadButton>
                        </td>
                    </tr>
                </table>                                

                <telerik:RadFileExplorer ID="FileExplorer1" runat="server"  EnableCopy="true" OnClientItemSelected="OnClientItemSelected">
                    <Configuration  MaxUploadFileSize="80000000"/>
                </telerik:RadFileExplorer>             

            </telerik:RadPageView>
            <telerik:RadPageView ID="RadPageView3" runat="server">
                <table>
                    <tr>
                        <td>
                            Embed Linki
                        </td>
                        <td>
                            <asp:TextBox ID="txtEmbedLink" runat="server"></asp:TextBox>
                        </td>
                    </tr>
                </table>                
            </telerik:RadPageView>
        </telerik:RadMultiPage>

    </div>
    <div class="IcerikGovdeGolge">

    </div>

    <div class="contentAlt30">
                  
        <telerik:RadButton Width="70px" ID="RadButton3" runat="server" Text="Geri" OnClick="btnGeri_Click"  >
             <Icon PrimaryIconUrl="~/Style/btnBack.png"/>
        </telerik:RadButton>  

        <telerik:RadButton Width="150px" ID="btnKaydet" runat="server" Text="Kaydet" OnClick="btnKaydet_Click" >
        </telerik:RadButton>   
        
        <telerik:RadButton Width="150px" ID="btnSil" runat="server" Text="Sil" OnClick="btnSil_Click" >
        </telerik:RadButton>            
 
    </div>
    <div  class="contentAlt30Golge">

    </div>


</asp:Content>
