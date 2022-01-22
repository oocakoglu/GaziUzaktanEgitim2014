namespace GaziProje2014.Migrations
{
    using GaziProje2014.Data.Models;
    using System;
    using System.Data.Entity;
    using System.Data.Entity.Migrations;
    using System.Linq;

    internal sealed class Configuration : DbMigrationsConfiguration<GaziProje2014.Data.GAZIDbContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
        }

        protected override void Seed(GaziProje2014.Data.GAZIDbContext context)
        {
            //  This method will be called after migrating to the latest version.
           //  You can use the DbSet<T>.AddOrUpdate() helper extension method
            //  to avoid creating duplicate seed data.
        }
    }
}
