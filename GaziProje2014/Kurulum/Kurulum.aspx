<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Kurulum.aspx.cs" Inherits="GaziProje2014.Kurulum.Kurulum" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style>
        .form-control {
            display: block;
            width: 270px;
            height: 30px;
            padding: 6px 12px;
            font-size: 14px;
            line-height: 1.428571429;
            color: #555555;
            vertical-align: middle;
            background-color: #ffffff;
            /*background-color:#5e7ca0;*/
            background-image: none;
            border: 1px solid #cccccc;
            border-radius: 4px;
            -webkit-box-shadow: inset 0 5px 5px rgba(0, 0, 0, 0.075);
            box-shadow: inset 0 5px 5px rgba(0, 0, 0, 0.075);
            -webkit-transition: border-color ease-in-out 0.85s, box-shadow ease-in-out 0.85s;
            transition: border-color ease-in-out 0.85s, box-shadow ease-in-out 0.85s;
        }

        .Hucre {
            padding: 5px;
        }

        .UstBaslik {
            font-size: 24px;
            font-weight: 100;
            font-style: normal;
        }

        .Girisbutton {
            background-color: #5bc0de;
          
            display: inline-block;
            padding: 6px 12px;
            margin-bottom: 0;
            font-size: 14px;
            font-weight: normal;
            line-height: 1.428571429;
            text-align: center;
            white-space: nowrap;
            vertical-align: middle;
            cursor: pointer;
            background-image: none;
            border: 1px solid transparent;
            border-radius: 4px;
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            -o-user-select: none;
            user-select: none;
        }
    </style>

</head>
<body>
    <form id="form1" runat="server">
      <div>
          <telerik:RadScriptManager ID="RadScriptManager1" runat="server"></telerik:RadScriptManager>

           <telerik:RadTabStrip ID="rtbstMain" runat="server" MultiPageID="soruMultiPage" SelectedIndex="0" Visible="true">
               <Tabs>

                   <telerik:RadTab runat="server" Text="1. Adım" Selected="True" PageViewID="rdpageGoruntule">
                   </telerik:RadTab>

                   <telerik:RadTab runat="server" Text="2. Adım"  PageViewID="rdpageDuzenle">
                   </telerik:RadTab>

               </Tabs>
           </telerik:RadTabStrip>

            <telerik:RadMultiPage ID="soruMultiPage" runat="server" SelectedIndex="0">
                <telerik:RadPageView ID="rdpageGoruntule" runat="server">
                   
                    <fieldset class="fieldsetForm">                        
                        <table>
                            <tr>
                                <td>     
                                    <asp:Label ID="Label1" runat="server" Text="Server Adı (Database):"></asp:Label>                
                                </td>                 
                                <td>
                                    <asp:TextBox ID="txtServerName" runat="server" CssClass="form-control">.\TUKETICI2013</asp:TextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>     
                                    <asp:Label ID="Label2" runat="server" Text="Database Adı:"></asp:Label>                
                                </td>                 
                                <td>
                                    <asp:TextBox ID="txtDataBaseName" runat="server"  CssClass="form-control">GAZITEST</asp:TextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>     
                                    <asp:Label ID="Label3" runat="server" Text="Database Kullanıcı Adı:"></asp:Label>                
                                </td>                 
                                <td>
                                    <asp:TextBox ID="txtDataBaseUser" runat="server"  CssClass="form-control">sa</asp:TextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>     
                                    <asp:Label ID="Label4" runat="server" Text="Database Kullanıcı Şifre:"></asp:Label>                
                                </td>                 
                                <td>
                                    <asp:TextBox ID="txtDataBaseSifre" runat="server"  CssClass="form-control">111222333</asp:TextBox>
                                </td>
                            </tr>

                            <tr>
                                <td>     
                                    <asp:Button ID="btnDatabaseTanim" runat="server" Text="Tanımla" CssClass="Girisbutton" OnClick="btnDatabaseTanim_Click"/>        
                                </td>                 
                                <td>
              
                                </td>
                            </tr>

                        </table>
                    </fieldset>  
                            
                </telerik:RadPageView>
                <telerik:RadPageView ID="rdpageDuzenle" runat="server">
                
                
                </telerik:RadPageView>
           </telerik:RadMultiPage>

          <asp:TextBox ID="txtDurum" runat="server" ReadOnly="True" TextMode="MultiLine"></asp:TextBox>


<asp:Button ID="btnDataBase" runat="server" Text="Database Tabloları Olustur" OnClick="btnDataBase_Click"  CssClass="Girisbutton"/>

      </div>
    </form>
</body>
</html>
