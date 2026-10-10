using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Data
{
    public class TourDbContext : DbContext
    {
        public TourDbContext(DbContextOptions<TourDbContext> options) : base(options) { }

        public DbSet<Lugar> Lugares { get; set; }
        public DbSet<Escena> Escenas { get; set; }
        public DbSet<Hotspot> Hotspots { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Hotspot>()
                .HasOne(h => h.EscenaOrigen)
                .WithMany(e => e.HotspotsOrigen)
                .HasForeignKey(h => h.EscenaOrigenId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Hotspot>()
                .HasOne(h => h.EscenaDestino)
                .WithMany()
                .HasForeignKey(h => h.EscenaDestinoId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}