using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014
{
    public partial class SiteCss : System.Web.UI.MasterPage
    {


        //testSpace.Style.Add("display", "none");


        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            string backGround = "background: url(/Style/Images/ArkaPlan2.jpg) no-repeat center center fixed;";
            if (Session["BackGround"] != null)
            {
                backGround = Session["BackGround"].ToString();
                backGround = "background: url(" + backGround + ") no-repeat center center fixed;";
            }

            HtmlGenericControl itemStyle = new HtmlGenericControl("style");
            itemStyle.Attributes.Add("type", "text/css");
            itemStyle.InnerHtml = "html "
                                + "{"
                                + backGround
                                + "-webkit-background-size: cover;"
                                + "-moz-background-size: cover;"
                                + "-o-background-size: cover;"
                                + "background-size: cover;"
                                + "height: 100%;"
                                + "}";


            Page.Header.Controls.Add(itemStyle);
            if (Session["SkinName"] != null)
                QsfSkinManager.Skin = Session["SkinName"].ToString();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                //int KullaniciTipiId = 1;
                int KullaniciTipiId = Convert.ToInt32(Session["KullaniciTipiId"].ToString());   
                
                string kullaniciMenu = "Menu" + KullaniciTipiId.ToString();
                List<Formlar> lstForm;

                //DataTable dtForm;
                lstForm = (List<Formlar>)Cache[kullaniciMenu];
                if (lstForm == null)
                {
                    using (GAZIDbContext gaziEntities = new GAZIDbContext())
                    {
                        List<int> formIds = gaziEntities.KullaniciFormlar.Where(q => q.KullaniciTipiId == KullaniciTipiId && q.FormYetki == true).Select(q => q.FormId.Value).ToList();
                        lstForm = gaziEntities.Formlar.Where(q => formIds.Contains(q.Id) && q.PId != null).ToList();
                       
                        List<int> pIds = lstForm.Select(q => q.PId.Value).ToList();
                        List<Formlar> pForms = gaziEntities.Formlar.Where(q => pIds.Contains(q.Id) && q.PId == null).ToList();
                        lstForm = lstForm.Concat(pForms).ToList();
                     }
                    Cache.Insert(kullaniciMenu, lstForm, null, DateTime.Now.AddMinutes(5), TimeSpan.Zero);
                }
                FormCreateNode(null, null, lstForm);
                string url = Request.Url.ToString();

                //** Giriş Sayası ise
                if (url.IndexOf("DefaultDuyuru") > 0)
                {
                    if (RadPanelBar1.Items.Count > 0)
                    {
                        RadPanelItem rdust = RadPanelBar1.Items[0];
                        rdust.Expanded = true;
                    }
                }
                else
                {
                    int ind = url.IndexOf("/Forms/");
                    url = url.Substring(ind, url.Length - ind);

                    RadPanelItem rdi = RadPanelBar1.FindItemByUrl(url);
                    if (rdi != null)    
                    {
                        RadPanelItem rdust = (RadPanelItem)rdi.Parent;
                        rdust.Expanded = true;
                    }
                }
            }


            if (Session["Mesaj"] != null)
            {
                RadNotification1.Text = Session["Mesaj"].ToString();
                RadNotification1.Show();
                Session.Remove("Mesaj");
            }


        }
        
        private void FormCreateNode(int? AktifParentId, RadPanelItem RootNode, List<Formlar> FormList)
        {

            List<Formlar> FormBaslik = FormList.Where(x => x.PId == AktifParentId).ToList();

            foreach (Formlar items in FormBaslik)
            {
                RadPanelItem dateItem = new RadPanelItem();
                dateItem.Text = items.FormBaslik;
                dateItem.CssClass = "MainItem";
                dateItem.NavigateUrl = items.FormAdi;

                if (items.FormImageUrl != null && items.FormImageUrl != "")
                    dateItem.ImageUrl = items.FormImageUrl;
                else
                    dateItem.ImageUrl = "http://demos.telerik.com/aspnet-ajax/panelbar/examples/overview/Images/contacts.gif";
                //RadPanelBar1.Items.Add(dateItem);

                if (RootNode != null)
                    RootNode.Items.Add(dateItem);
                else
                    RadPanelBar1.Items.Add(dateItem);

                FormCreateNode(items.Id, dateItem, FormList);
            }
        }

        protected void CikisButton_Click(object sender, ImageClickEventArgs e)
        {
            Session.Remove("KullaniciAdi");
            Session.Remove("KullaniciId");
            Session.Remove("KullaniciTipiId");
            Session.Remove("SkinName");
            Session.Remove("BackGround");

            //Response.Redirect("~/Login.aspx");
            //Response.Redirect("~/HizliGiris.aspx");
            Response.Redirect("~/Default.aspx");
        }

        protected void QsfSkinManager_SkinChanged(object sender, SkinChangedEventArgs e)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();
            int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());
            Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
            kullanici.SkinName = e.Skin;
            gaziEntities.SaveChanges();

            Session.Add("SkinName", e.Skin);
        }


    }
}