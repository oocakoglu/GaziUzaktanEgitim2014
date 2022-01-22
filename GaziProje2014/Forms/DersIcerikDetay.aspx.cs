using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;

namespace GaziProje2014.Forms
{
    public partial class DersIcerikDetay : System.Web.UI.Page
    {
        private void FillForm(int icerikId)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();
            DersIcerikler dersIcerik = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();

            //**Dersler Yukleniyor (Tek Ders)
            var dersler = (from od in gaziEntities.OgretmenDersler
                           where od.OgretmenDersId == dersIcerik.OgretmenDersId && od.UstOnay == true
                           join d in gaziEntities.Dersler on od.DersId equals d.DersId
                           select new { od.OgretmenDersId, d.DersAdi }).Take(100).ToList();

            rdDersler.DataSource = dersler;
            rdDersler.DataValueField = "OgretmenDersId";
            rdDersler.DataTextField = "DersAdi";
            rdDersler.DataBind();
            rdDersler.Enabled = false;


            //** Konular Yukleniyor
            var konular = (from di in gaziEntities.DersIcerikler
                           where di.OgretmenDersId == dersIcerik.OgretmenDersId
                           select new { di.IcerikId, di.IcerikPId, di.IcerikAdi }).Take(100).ToList();

            rdcbUstBaslik.DataSource = konular;
            rdcbUstBaslik.DataTextField = "IcerikAdi";
            rdcbUstBaslik.DataValueField = "IcerikId";
            rdcbUstBaslik.DataFieldID = "IcerikId";
            rdcbUstBaslik.DataFieldParentID = "IcerikPId";
            rdcbUstBaslik.DefaultValue = "";
            rdcbUstBaslik.DataBind();


            if (dersIcerik.IcerikPId != null)
                rdcbUstBaslik.SelectedValue = dersIcerik.IcerikPId.ToString();
            else
                chkUstKonu.Checked = true;

            txtKonuAdi.Text = dersIcerik.IcerikAdi;
            txtDisUrlName.Text = dersIcerik.UrlName;
            chkPublic.Checked = dersIcerik.GenelIcerik.Value;
                     

            int IcerikTip = dersIcerik.IcerikTip.Value;
            rdDersEditor.Content = dersIcerik.IcerikText;
            if (IcerikTip == 1)
            {
                dersMultiPage.SelectedIndex = 0;
                rbList.SelectedValue = "1";
                rdDersEditor.Content = dersIcerik.IcerikText;
            }
            else if (IcerikTip == 2)
            {
                dersMultiPage.SelectedIndex = 1;
                rbList.SelectedValue = "2";
                fileName.Text = dersIcerik.IcerikUrl;
            }
            else if (IcerikTip == 3)
            {
                dersMultiPage.SelectedIndex = 2;
                rbList.SelectedValue = "3";
                txtEmbedLink.Text = dersIcerik.IcerikUrl;
            }
        }

        private void CheckDokumanAdres(int kullaniciId)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();

            //** Ogretmen Path
            string DokumanAdres = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).Select(q => q.DokumanAdres).SingleOrDefault();

            if (DokumanAdres == null)
            {
                Kullanicilar kullanicilar = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
                DokumanAdres = kullanicilar.Adi + kullanicilar.Soyadi;
                DokumanAdres = "~/Dokumanlar/" + Common.SefURL(DokumanAdres);
                kullanicilar.DokumanAdres = DokumanAdres;
                gaziEntities.SaveChanges();

                string sDirPath = Server.MapPath(DokumanAdres);
                DirectoryInfo ObjSearchDir = new DirectoryInfo(sDirPath);
                if (!ObjSearchDir.Exists)
                {
                    ObjSearchDir.Create();
                }
            }
            //FileExplorer1.Configuration.ViewPaths = new string[] { "~/Dokumanlar/TolgaKecik" };
            FileExplorer1.Configuration.ViewPaths = new string[] { DokumanAdres };
            FileExplorer1.Configuration.UploadPaths = new string[] { DokumanAdres };
            FileExplorer1.Configuration.DeletePaths = new string[] { DokumanAdres };
        }

        protected void Page_Load(object sender, EventArgs e)
        {

            if (!IsPostBack)
            {
                int kullaniciId = Convert.ToInt32(Session["KullaniciId"].ToString());   
                CheckDokumanAdres(kullaniciId);
                if (Session["DersIcerikId"] != null)
                {
                    int icerikId = Convert.ToInt32(Session["DersIcerikId"]);
                    FillForm(icerikId);
                }
                else
                {
                    GAZIDbContext gaziEntities = new GAZIDbContext();
                    if (kullaniciId == 1)
                    {
                        //**Dersler Yukleniyor (Tek Ders)                        
                        var dersler = (from od in gaziEntities.OgretmenDersler
                                       join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                       select new { od.OgretmenDersId, d.DersAdi }).Take(100).ToList();

                        rdDersler.DataSource = dersler;
                        rdDersler.DataValueField = "OgretmenDersId";
                        rdDersler.DataTextField = "DersAdi";
                        rdDersler.DataBind();
                    }
                    else
                    {                  
                        //**Dersler Yukleniyor (Tek Ders)
                        var dersler = (from od in gaziEntities.OgretmenDersler
                                       where od.OgretmenId == kullaniciId && od.UstOnay == true
                                       join d in gaziEntities.Dersler on od.DersId equals d.DersId
                                       select new { od.OgretmenDersId, d.DersAdi });
                                       //select new { od.OgretmenDersId, d.DersAdi }).Take(100).ToList();

                        if (Session["OgretmenDersId"] != null)
                        {
                            int ogretmenDersId = Convert.ToInt32(Session["OgretmenDersId"]);
                            dersler = dersler.Where(q => q.OgretmenDersId == ogretmenDersId);
                            rdDersler.Enabled = false;
                        }

                        rdDersler.DataSource = dersler.Take(100).ToList();
                        rdDersler.DataValueField = "OgretmenDersId";
                        rdDersler.DataTextField = "DersAdi";
                        rdDersler.DataBind();
                    }

                    if (rdDersler.SelectedValue != "")
                    {
                        int ogretmenDersId = Convert.ToInt32(rdDersler.SelectedValue);
                        var konular = (from di in gaziEntities.DersIcerikler
                                       where di.OgretmenDersId == ogretmenDersId
                                       select new { di.IcerikId, di.IcerikPId, di.IcerikAdi }).Take(100).ToList();

                        rdcbUstBaslik.DataSource = konular;
                        rdcbUstBaslik.DataTextField = "IcerikAdi";
                        rdcbUstBaslik.DataValueField = "IcerikId";
                        rdcbUstBaslik.DataFieldID = "IcerikId";
                        rdcbUstBaslik.DataFieldParentID = "IcerikPId";
                        rdcbUstBaslik.DefaultValue = "";
                        rdcbUstBaslik.DataBind();
                    }
                }
            }


        }

        protected void btnDosyaSec_Click(object sender, EventArgs e)
        {
            var aa = FileExplorer1.OnClientItemSelected;
        }

        protected void chkUstKonu_CheckedChanged(object sender, EventArgs e)
        {
            if (chkUstKonu.Checked)
            {
                rdcbUstBaslik.SelectedValue = "0";
                rdcbUstBaslik.Enabled = false;
            }
            else
            {
                rdcbUstBaslik.Enabled = true;
            }
        }

        protected void btnKaydet_Click(object sender, EventArgs e)
        {
            GAZIDbContext gaziEntities = new GAZIDbContext();
            DersIcerikler dersIcerikler;
            if (Session["DersIcerikId"] != null)
            {
                int icerikId = Convert.ToInt32(Session["DersIcerikId"].ToString());
                dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikId == icerikId).FirstOrDefault();
            }
            else
            {
                dersIcerikler = new DersIcerikler();
                gaziEntities.DersIcerikler.Add(dersIcerikler);
            }

            if (chkUstKonu.Checked || rdcbUstBaslik.SelectedValue == "")
            {
                dersIcerikler.IcerikPId = null;
                dersIcerikler.IconUrl = "~/Style/ArsivAna.png";
            }
            else
            { 
                dersIcerikler.IcerikPId = Convert.ToInt32(rdcbUstBaslik.SelectedValue);
                dersIcerikler.IconUrl = "~/Style/folder.png";
            }

            dersIcerikler.OgretmenDersId = Convert.ToInt32(rdDersler.SelectedValue);
            dersIcerikler.IcerikAdi = txtKonuAdi.Text;
          
            int icerikTipId = Convert.ToInt32(rbList.SelectedValue);
            dersIcerikler.IcerikText = rdDersEditor.Content;
            dersIcerikler.GenelIcerik = chkPublic.Checked;
            dersIcerikler.UrlName = txtDisUrlName.Text;

            if (icerikTipId == 1)
            {
                dersIcerikler.IcerikTip = 1;
                dersIcerikler.IcerikText = rdDersEditor.Content;
                dersIcerikler.IcerikUrl = null;
            }
            else if (icerikTipId == 2)
            {
                dersIcerikler.IcerikTip = 2;
                //dersIcerikler.IcerikText = null;
                dersIcerikler.IcerikUrl = fileName.Text;
            }
            else if (icerikTipId == 3)
            {
                dersIcerikler.IcerikTip = 3;
                //dersIcerikler.IcerikText = null;
                dersIcerikler.IcerikUrl = txtEmbedLink.Text;
            }
            //dersIcerikler.EkleyenId = Convert.ToInt32(Session["KullaniciId"].ToString());
            

            dersIcerikler.EkleyenId = 1;
            dersIcerikler.KayitTarihi = DateTime.Now;
            gaziEntities.SaveChanges();
            btnGeri_Click(null, null);
        }

        protected void btnSil_Click(object sender, EventArgs e)
        {
            if (Session["DersIcerikId"] != null)
            {
                GAZIDbContext gaziEntities = new GAZIDbContext();
                int icerikId = Convert.ToInt32(Session["DersIcerikId"].ToString());
                List<DersIcerikler> dersIcerikler = gaziEntities.DersIcerikler.Where(q => q.IcerikPId == icerikId || q.IcerikId == icerikId).ToList();
                foreach (DersIcerikler dersIcerik in dersIcerikler)
                {
                    gaziEntities.DersIcerikler.Remove(dersIcerik);
                }
                gaziEntities.SaveChanges();
                btnGeri_Click(null, null);
            }
        }

        protected void btnGeri_Click(object sender, EventArgs e)
        {        
            Session.Remove("DersIcerikId");
            Session.Add("OgretmenDersId", rdDersler.SelectedValue);
            Response.Redirect("~/Forms/DersIcerikYoneticisi.aspx");
        }

        protected void RadDropDownList1_ItemSelected(object sender, Telerik.Web.UI.DropDownListEventArgs e)
        {

        }

        protected void rdDersler_SelectedIndexChanged(object sender, Telerik.Web.UI.DropDownListEventArgs e)
        {

            string ogretmenDersIdStr = rdDersler.SelectedValue;
            int ogretmenDersId = Convert.ToInt32(ogretmenDersIdStr);

            GAZIDbContext gaziEntities = new GAZIDbContext();
            //** Konular Yukleniyor
            var konular = (from di in gaziEntities.DersIcerikler
                           where di.OgretmenDersId == ogretmenDersId
                           select new { di.IcerikId, di.IcerikPId, di.IcerikAdi }).Take(100).ToList();

            rdcbUstBaslik.DataSource = konular;
            rdcbUstBaslik.DataTextField = "IcerikAdi";
            rdcbUstBaslik.DataFieldID = "IcerikId";
            rdcbUstBaslik.DataFieldParentID = "IcerikPId";
            rdcbUstBaslik.DefaultValue = "";
            rdcbUstBaslik.DataBind();
        }

        protected void btnDenetle_Click(object sender, EventArgs e)
        {            
            string DisUrl = SafeText(txtDisUrlName.Text);
            txtDisUrlName.Text = DisUrl;

            int icerikId = 0;
            if (Session["DersIcerikId"] != null)
                icerikId = Convert.ToInt32(Session["DersIcerikId"].ToString());

            GAZIDbContext gaziEntities = new GAZIDbContext();
            int UrlKontrol = gaziEntities.DersIcerikler.Where(q => q.UrlName == DisUrl && q.IcerikId != icerikId).Count();
            if (UrlKontrol == 0)
            {
                txtDisUrlName.BackColor = System.Drawing.Color.Green;
            }
            else
            {
                txtDisUrlName.BackColor = System.Drawing.Color.Red;
            }
        }

        public static string SafeText(string IncomingText)
        {
            System.Globalization.CultureInfo Dil = new System.Globalization.CultureInfo("tr-TR");

            IncomingText = IncomingText.Replace("ş", "s");
            IncomingText = IncomingText.Replace("Ş", "s");
            IncomingText = IncomingText.Replace("İ", "i");
            IncomingText = IncomingText.Replace("I", "i");
            IncomingText = IncomingText.Replace("ı", "i");
            IncomingText = IncomingText.Replace("ö", "o");
            IncomingText = IncomingText.Replace("Ö", "o");
            IncomingText = IncomingText.Replace("ü", "u");
            IncomingText = IncomingText.Replace("Ü", "u");
            IncomingText = IncomingText.Replace("Ç", "c");
            IncomingText = IncomingText.Replace("ç", "c");
            IncomingText = IncomingText.Replace("ğ", "g");
            IncomingText = IncomingText.Replace("Ğ", "g");
            IncomingText = IncomingText.Replace(" ", "-");
            IncomingText = IncomingText.Replace("---", "-");
            IncomingText = IncomingText.Replace("?", "");
            IncomingText = IncomingText.Replace("/", "");
            IncomingText = IncomingText.Replace(".", "");
            IncomingText = IncomingText.Replace("'", "");
            IncomingText = IncomingText.Replace("#", "");
            IncomingText = IncomingText.Replace("%", "");
            IncomingText = IncomingText.Replace("&", "");
            IncomingText = IncomingText.Replace("*", "");
            IncomingText = IncomingText.Replace("!", "");
            IncomingText = IncomingText.Replace("@", "");
            IncomingText = IncomingText.Replace("+", "");

            IncomingText = IncomingText.ToLower();
            IncomingText = IncomingText.Trim();
            return IncomingText;
        }

    }
}