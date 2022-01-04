<%@ Page Title="" Language="C#" MasterPageFile="~/SiteCss.Master" AutoEventWireup="true" CodeBehind="SinavDetay.aspx.cs" Inherits="GaziProje2014.Forms.SinavDetay" %>
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


        <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
            <script type="text/javascript">
                function refreshGrid(arg) {
                    if (!arg) {
                        $find("<%= RadAjaxManager1.ClientID %>").ajaxRequest("Rebind");
                    }
                    else {
                        $find("<%= RadAjaxManager1.ClientID %>").ajaxRequest("RebindAndNavigate");
                    }
                }
            </script>
        </telerik:RadCodeBlock>

        <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server" OnAjaxRequest="RadAjaxManager1_AjaxRequest">
            <AjaxSettings>
                <telerik:AjaxSetting AjaxControlID="RadAjaxManager1">
                    <UpdatedControls>
                        <telerik:AjaxUpdatedControl ControlID="RadListView1"></telerik:AjaxUpdatedControl>
                    </UpdatedControls>
                </telerik:AjaxSetting>
            </AjaxSettings>
        </telerik:RadAjaxManager>

    <div class="contentOrta00x40">
          <telerik:RadTabStrip ID="rtbstMain" runat="server" MultiPageID="RadMultiPage1" SelectedIndex="0">
               <Tabs>
                   <telerik:RadTab runat="server" TabIndex="0" Text="Sınav Detayları" Selected="True">
                   </telerik:RadTab>
                   <telerik:RadTab runat="server" TabIndex="1" Text="Soruları">
                   </telerik:RadTab>
               </Tabs>
           </telerik:RadTabStrip>
           <telerik:RadMultiPage ID="RadMultiPage1" runat="server" SelectedIndex="0">
               <telerik:RadPageView ID="RadPageView1" runat="server" TabIndex="0">  
                       
                   <table style="padding:20px;">
                       <tr>
                           <td>
                               <asp:Label ID="Label1" runat="server" Text="Ders Adı :"></asp:Label>
                           </td>
                           <td>
                               <telerik:RadComboBox ID="rdcmbOgretmenOnayliDersler" runat="server" Width="300px"></telerik:RadComboBox>
                                &nbsp;&nbsp;&nbsp;
                               <asp:CheckBox ID="chkGenelSinav" runat="server" AutoPostBack="true" OnCheckedChanged="chkGenelSinav_CheckedChanged" Text="Genel Sınav" />
                           </td>
                       </tr>

                       <tr>
                           <td>
                               <asp:Label ID="Label2" runat="server" Text="Sınav Adı :"></asp:Label>
                           </td>
                           <td>
                               <asp:TextBox ID="txtSinavAdi" runat="server"></asp:TextBox>   
                           </td>
                       </tr>

                       <tr>
                           <td>
                               <asp:Label ID="Label6" runat="server" Text="Süre :"></asp:Label>
                           </td>
                           <td>
                               <asp:TextBox ID="txtSinavSure" runat="server"></asp:TextBox>   
                           </td>
                       </tr>

                       <tr>
                           <td>
                               <asp:Label ID="Label4" runat="server" Text="Başlangıç Tarihi :"></asp:Label>
                           </td>
                           <td>
                               <telerik:RadDatePicker ID="dteBaslangicTarihi" runat="server" Culture="tr-TR"></telerik:RadDatePicker>   
                           </td>
                       </tr>

                       <tr>
                           <td>
                               <asp:Label ID="Label5" runat="server" Text="Bitiş Tarihi :"></asp:Label>
                           </td>
                           <td>                  
                               <telerik:RadDatePicker ID="dteBitisTarihi" runat="server" Culture="tr-TR"></telerik:RadDatePicker> 
                           </td>
                       </tr>

                       <tr>
                           <td>
                               <asp:Label ID="Label3" runat="server" Text="Sınav Açıklama :"></asp:Label>
                           </td>
                           <td>
                               <asp:TextBox ID="txtSinavAciklama" runat="server" Height="50px" TextMode="MultiLine" Width="275px"></asp:TextBox>   
                           </td>
                       </tr>

                       <tr>
                           <td>
                               
                           </td>
                           <td>                  
                               <asp:HiddenField ID="hdnSinavId" runat="server" />
                           </td>
                       </tr>
  
                   </table>    
                                            
               </telerik:RadPageView>
               <telerik:RadPageView ID="RadPageView2" runat="server" TabIndex="1">
                   <div>
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
        <%--                             <a href='<%# "ResimGoruntule.aspx?ResimAdi=images/"+ Eval("DogruCvp")+ "&genislik=599" %>' title=""><%# Eval("DogruCvp") %></a>--%>                            
                                    <asp:Label ID="CvpSayisiLabel" runat="server" Text='<%# Eval("SoruKonu") %>' /><br />
                                    <asp:Image ID="imgSoruResim" runat="server" ImageUrl='<%# Eval("SoruResim") %>' /><br />                                   
                                    <asp:Label ID="lblSinavDetayId" runat="server" Text='<%# Eval("SinavDetayId") %>' Visible="false" />
                                    <asp:Label ID="lblSoruId" runat="server" Text='<%# Eval("SoruId") %>' Visible="false" />
                                    <asp:Label ID="lblOgretmenDersId" runat="server" Text='<%# Eval("OgretmenDersId") %>' Visible="false" />

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
                                    <%--<telerik:RadButton ID="btnSoruDuzenle" runat="server" Text="Soruyu Düzenle" OnClick="btnSoruDuzenle_Click"></telerik:RadButton>--%>
                                    <telerik:RadButton ID="btnSoruCikar" runat="server" Text="Soruyu Sınavdan Çıkar" OnClick="btnSoruCikar_Click"></telerik:RadButton>
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
               </telerik:RadPageView>
               <telerik:RadPageView ID="RadPageView3" runat="server">
                   RadPageView3</telerik:RadPageView>
           </telerik:RadMultiPage>
    </div>

    <div class="contentAlt30">
        
        <telerik:RadButton Width="100px" ID="btnKaydet" runat="server" Text="Kaydet" OnClick="btnKaydet_Click"></telerik:RadButton>  
        <telerik:RadButton Width="100px" ID="btnSorEkle" runat="server" Text="Soru Ekle" OnClick="btnSoruEkle_Click"></telerik:RadButton>     
        <telerik:RadButton Width="100px" ID="btnSil" runat="server" Text="Sil"></telerik:RadButton>  

    </div>
    <div class="contentAlt30Golge"> 
    </div>


     <telerik:RadWindowManager ID="RadWindowManager1" runat="server"></telerik:RadWindowManager>
    <telerik:RadNotification ID="RadNotification1" runat="server" EnableRoundedCorners="true"
        EnableShadow="true" Text="Sample content" Title="Bilgilendirme" Width="300" Height="100">
    </telerik:RadNotification>

</asp:Content>
