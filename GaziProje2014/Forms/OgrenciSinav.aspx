<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="OgrenciSinav.aspx.cs" Inherits="GaziProje2014.Forms.OgrenciSinav" %>
<%@ Register TagPrefix="telerik" Namespace="Telerik.Web.UI" Assembly="Telerik.Web.UI" %>


<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="../Style/css/Site.css" rel="stylesheet" />
    <link href="../Style/css/Site.css" rel="stylesheet" type="text/css" />

    <style>

        .SurePanel{            
            background-image: url('/Style/Images/Saat.png');  
            
            height:95px;
            width:235px;
            padding-top:150px;
            padding-left:10px;
            padding-right:5px;
        }



        .legendForm {
            padding: 4px;
            position: absolute;
            left: 10px;
            top: -11px;
            background-color: #2DABC1; /*#4F709F;*/
            color: white;
            -webkit-border-radius: 4px;
            -moz-border-radius: 4px;
            border-radius: 4px;
            box-shadow: 2px 2px 4px #888;
            -moz-box-shadow: 2px 2px 4px #888;
            -webkit-box-shadow: 2px 2px 4px #888;
            text-shadow: 1px 1px 1px #333;
        }

        .fieldsetForm {
            position: relative;
            padding: 10px;                
            margin-bottom: 30px;
            background: #F6F6F6;
            -webkit-border-radius: 8px;
            -moz-border-radius: 8px;
            border-radius: 8px;
            background: -webkit-gradient(linear, left top, left bottom, from(#EFEFEF), to(#FFFFFF));
            background: -moz-linear-gradient(center top, #EFEFEF, #FFFFFF 100%);
            box-shadow: 3px 3px 10px #ccc;
            -moz-box-shadow: 3px 3px 10px #ccc;
            -webkit-box-shadow: 3px 3px 10px #ccc;
        }

    </style>

</head>
<body>
    <form id="form1" runat="server">


<%--        <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
            <Scripts>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.Core.js"></asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQuery.js"></asp:ScriptReference>
                <asp:ScriptReference Assembly="Telerik.Web.UI" Name="Telerik.Web.UI.Common.jQueryInclude.js"></asp:ScriptReference>
            </Scripts>
        </telerik:RadScriptManager>--%>



        <div id="header">
            <div id="logo">
            </div>
            <%-- 
            <div style="float: right; margin-top: 10px; margin-right: 10px;">
                <asp:imagebutton runat="server" Id="CikisButton" ImageUrl="~/Style/Cikis.png" OnClick="CikisButton_Click"></asp:imagebutton>
                <br />
                <telerik:RadSkinManager ID="QsfSkinManager" runat="server" ShowChooser="true" OnSkinChanged="QsfSkinManager_SkinChanged" />
                <telerik:RadFormDecorator ID="QsfFromDecorator" runat="server" DecoratedControls="All" EnableRoundedCorners="false" />
            </div>   
            --%>     
                <asp:imagebutton runat="server" Id="CikisButton" ImageUrl="~/Style/Cikis.png" OnClick="CikisButton_Click"></asp:imagebutton>
                <br />
                <telerik:RadSkinManager ID="QsfSkinManager" runat="server" ShowChooser="true" OnSkinChanged="QsfSkinManager_SkinChanged" />
                <telerik:RadFormDecorator ID="QsfFromDecorator" runat="server" DecoratedControls="All" EnableRoundedCorners="false" />
        </div>

        <div id="leftMenu">
            <asp:HiddenField ID="hdnOgrenciSinavId" runat="server" />
            <asp:ScriptManager ID= "SM1" runat="server"></asp:ScriptManager>
            <asp:Timer ID="timer1" runat="server" Interval="10000" OnTick="timer1_tick"></asp:Timer>  

            <div class="SurePanel">
                <asp:UpdatePanel id="updPnl"  runat="server" UpdateMode="Conditional">                   
                    <ContentTemplate>
                        <table>
                            <tr>
                                <td>
                                    <asp:Label ID="Label1" runat="server" Text="Başlangıç Zamanı"></asp:Label>
                                </td>
                                <td>
                                    :&nbsp;<asp:Label ID="lblBaslangicTarihi" runat="server" ></asp:Label>
                                </td>
                            </tr>

                            <tr>
                                <td>
                                    <asp:Label ID="Label2" runat="server" Text="Bitiş Zamanı"></asp:Label>
                                </td>
                                <td>
                                    :&nbsp;<asp:Label ID="lblBitisTarihi" runat="server" ></asp:Label>
                                </td>
                            </tr>

                            <tr>
                                <td>
                                    <asp:Label ID="Label3" runat="server" Text="Kalan Dakika"></asp:Label>
                                </td>
                                <td>
                                    :&nbsp;<asp:Label ID="lblBilgilendirme" runat="server" Text="Label"></asp:Label>  
                                </td>
                            </tr>
                        </table>
                        
                    </ContentTemplate>
                    <Triggers>
                        <asp:AsyncPostBackTrigger ControlID="timer1" EventName ="tick" />
                    </Triggers>
                </asp:UpdatePanel>
            </div>

               
                        

<%--                //   Add the update panel, 
                //a label to show the time remaining and the AsyncPostBackTrigger.  --%> 
   




        </div>

        <div id="content">
            
           <div class="contentOrta00x40">
                <telerik:RadListView ID="RadListView1" runat="server" DataKeyNames="SinavDetayId, SoruId"  OnItemDataBound="RadListView1_ItemDataBound">
                    <LayoutTemplate>
                        <div style="width:800px;">
                            <ul>
                                <li id="itemPlaceholder" runat="server"></li>
                            </ul>
                        </div>
                    </LayoutTemplate>
                    <ItemTemplate>                  
                            <fieldset class="fieldsetForm">
                                <p>
                                <legend class="legendForm">&nbsp;Soru&nbsp;</legend>
                                <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("SoruResim") %>' /><br />                                   
                                <asp:Label ID="SoruId" runat="server" Text='<%# Eval("SoruId") %>' Visible="false" />

                                <asp:Label ID="lblSoruIcerik" runat="server" Text='<%# Eval("SoruIcerik") %>' />                      
                                    
                                <asp:Label ID="lblCvpSayisi" runat="server" Text='<%# Eval("CvpSayisi") %>'  Visible="false"/>
                                <asp:Label ID="lblDogruCvp" runat="server" Text='<%# Eval("DogruCvp") %>' Visible="false"/>
                                </p>

                                <asp:RadioButtonList ID="rblCvp" runat="server">
                                </asp:RadioButtonList>
                                &nbsp;<asp:Label ID="Cvp1Label" runat="server" Text='<%# Eval("Cvp1") %>' Visible="false" />
                                &nbsp;<asp:Label ID="Cvp2Label" runat="server" Text='<%# Eval("Cvp2") %>'  Visible="false"/>
                                &nbsp;<asp:Label ID="Cvp3Label" runat="server" Text='<%# Eval("Cvp3") %>'  Visible="false"/>
                                &nbsp;<asp:Label ID="Cvp4Label" runat="server" Text='<%# Eval("Cvp4") %>'  Visible="false"/>
                                &nbsp;<asp:Label ID="Cvp5Label" runat="server" Text='<%# Eval("Cvp5") %>'  Visible="false"/><br />                               
                            </fieldset>                 
                    </ItemTemplate>
                    <EmptyDataTemplate>
                        <div>
                            Sınav için Soru Bulunamadı                        
                        </div>
                    </EmptyDataTemplate>
                </telerik:RadListView>
            </div>

            <div class="contentAlt30">
                <telerik:RadButton Width="150px" ID="btnSinaviBitir" runat="server" Text="Sınavı Bitir" OnClick="btnSinaviBitir_Click" ></telerik:RadButton>     
            </div>
            <div class="contentAlt30Golge">
                 
            </div>
        </div>

        

        <div id="footer">

        </div>



    </form>
</body>
</html>
