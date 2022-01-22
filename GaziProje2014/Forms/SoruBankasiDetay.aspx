<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="SoruBankasiDetay.aspx.cs" Inherits="GaziProje2014.Forms.SoruBankasiDetay" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">

    <style>
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

    <div class="contentUst40">
        <table class="tdTablo">
            <tr>
                <td class="tdCellBaslik">Ders Adı :</td>
                <td colspan="4">
                    <telerik:RadComboBox ID="rdDersler" runat="server" Width="500px" OnSelectedIndexChanged="rdDersler_SelectedIndexChanged" AutoPostBack="true" >
                    </telerik:RadComboBox>
                </td>
                <td class="tdCellBaslik"></td>                                                                                       
            </tr>
        </table>
    </div>
    <div class="contentUst40Golge">
    </div>

    <div class="contentOrta40x40">    

        <telerik:RadListView ID="rdListSorular" runat="server" DataKeyNames="SoruId"  OnItemDataBound="RadListView1_ItemDataBound">
            <LayoutTemplate>
                <div style="width:800px;">
                    <ul>
                        <li id="itemPlaceholder" runat="server"></li>
                        <li> 
                            <fieldset class="fieldsetForm">
                            <p>
                                <legend class="legendForm">Soru Ekle</legend>
                                <telerik:RadButton ID="btnSoruEkle" runat="server" Text="Yeni Soru Yaz" OnClick="btnYeniSoru_Click"></telerik:RadButton>                            
                            </fieldset>
                        </li>
                    </ul>
                    <div>
                        <asp:Button ID="btnInitInsert" runat="server" Text="Soru Ekle"/>
                    </div>
                </div>
            </LayoutTemplate>
            <ItemTemplate>                  
                    <fieldset class="fieldsetForm">
                        <p>
                        <legend class="legendForm">&nbsp;Soru&nbsp;</legend>                         
                        <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("SoruResim") %>' /><br />                                                      
                        &nbsp;<asp:Label ID="lblSoruId" runat="server" Text='<%# Eval("SoruId") %>' Visible="false" />
                        &nbsp;<asp:Label ID="lblOgretmenDersId" runat="server" Text='<%# Eval("OgretmenDersId") %>' Visible="false" />

                        &nbsp;<asp:Label ID="lblSoruIcerik" runat="server" Text='<%# Eval("SoruIcerik") %>' />                      
                        &nbsp;<asp:Label ID="CvpSayisiLabel" runat="server" Text='<%# Eval("SoruKonu") %>' Visible="false" />
                        &nbsp;<asp:Label ID="lblCvpSayisi" runat="server" Text='<%# Eval("CvpSayisi") %>' Visible="false" />
                        &nbsp;<asp:Label ID="lblDogruCvp" runat="server" Text='<%# Eval("DogruCvp") %>' Visible="false"/>
                        </p>

                        <asp:RadioButtonList ID="rblCvp" runat="server">
                        </asp:RadioButtonList>
                        &nbsp;<asp:Label ID="Cvp1Label" runat="server" Text='<%# Eval("Cvp1") %>' Visible="false" />
                        &nbsp;<asp:Label ID="Cvp2Label" runat="server" Text='<%# Eval("Cvp2") %>'  Visible="false"/>
                        &nbsp;<asp:Label ID="Cvp3Label" runat="server" Text='<%# Eval("Cvp3") %>'  Visible="false"/>
                        &nbsp;<asp:Label ID="Cvp4Label" runat="server" Text='<%# Eval("Cvp4") %>'  Visible="false"/>
                        &nbsp;<asp:Label ID="Cvp5Label" runat="server" Text='<%# Eval("Cvp5") %>'  Visible="false"/><br />                               
                        <telerik:RadButton ID="btnSoruDuzenle" runat="server" Text="Soruyu Düzenle" OnClick="btnSoruDuzenle_Click"></telerik:RadButton>
                        <telerik:RadButton ID="btnSoruCikar" runat="server" Text="Soruyu Sil"></telerik:RadButton>
                    </fieldset>                 
            </ItemTemplate>
            <EmptyDataTemplate>
                <div class="RadListView RadListView_Office2010Black">
                    <div class="rlvEmpty">
                        Henüz Hiç Soru Girilmedi
                    </div>
                </div>
            </EmptyDataTemplate>
    </telerik:RadListView>


    </div>            
    <div class="contentAlt30">
        <telerik:RadButton Width="70px" ID="RadButton3" runat="server" Text="Geri" OnClick="btnGeri_Click"  >
             <Icon PrimaryIconUrl="~/Style/btnBack.png"/>
        </telerik:RadButton> 

        <telerik:RadButton Width="150px" ID="btnDersIcerikGoruntule" runat="server" Text="Hadi Bakalım" ></telerik:RadButton> 
    </div>
    <div class="contentAlt30Golge"> 
    </div>

</asp:Content>
