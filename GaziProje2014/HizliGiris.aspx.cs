using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using GaziProje2014.Data;
using GaziProje2014.Data.Models;
using Telerik.Web.UI;

namespace GaziProje2014
{
    public partial class HizliGiris : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }



        protected void grdKullanici_NeedDataSource(object source, GridNeedDataSourceEventArgs e)
        {
            using (GAZIDbContext gaziEntities = new GAZIDbContext())
            {
                var data =
                    from k in gaziEntities.Kullanicilar
                    join kt in gaziEntities.KullaniciTipleri on k.KullaniciTipi equals kt.KullaniciTipId
                    select new
                    {
                        KullaniciId = k.KullaniciId, // or pc.ProdId
                        KullaniciTipId = kt.KullaniciTipId,
                        KullaniciAdi = k.KullaniciAdi,
                        KullaniciTipAdi = kt.KullaniciTipAdi,
                        Adi = k.Adi,
                        Soyadi = k.Soyadi
                    };
                grdKullanici.DataSource = data.ToList();
            }
        }

        protected void btnAdmin_Click(object sender, EventArgs e)
        {
            if (grdKullanici.SelectedItems.Count > 0)
            {
                int kullaniciId = Convert.ToInt32(grdKullanici.SelectedValues["KullaniciId"].ToString());

                GAZIDbContext gaziEntities = new GAZIDbContext();
                Kullanicilar kullanici = gaziEntities.Kullanicilar.Where(q => q.KullaniciId == kullaniciId).FirstOrDefault();
                if (kullanici != null)
                {
                    Session.Remove("KullaniciAdi");
                    Session.Remove("KullaniciId");
                    Session.Remove("KullaniciTipiId");

                    Session.Add("KullaniciAdi", kullanici.KullaniciAdi);
                    Session.Add("KullaniciId", kullanici.KullaniciId);
                    Session.Add("KullaniciTipiId", kullanici.KullaniciTipi);


                    //** Skin
                    if ((kullanici.SkinName != "") && (kullanici.SkinName != null))
                        Session.Add("SkinName", kullanici.SkinName);
                    else
                        Session.Add("SkinName", "WebBlue");

                    //** BackGround
                    if ((kullanici.BackGround != "") && (kullanici.BackGround != null))
                        Session.Add("BackGround", kullanici.BackGround);
                    else
                        Session.Add("BackGround", "/Style/Background/Back03.jpg");

                    Response.Redirect("~/Forms/DefaultDuyuru.aspx");
                }
            }
        }


    }
}