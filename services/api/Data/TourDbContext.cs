using Microsoft.EntityFrameworkCore;
using TourVirtualUTB.Api.Models;

namespace TourVirtualUTB.Api.Data;

public class TourDbContext(DbContextOptions<TourDbContext> options) : DbContext(options)
{
    public DbSet<Lugar> Lugares => Set<Lugar>();
    public DbSet<Poi> Pois => Set<Poi>();
    public DbSet<Escena> Escenas => Set<Escena>();
    public DbSet<Hotspot> Hotspots => Set<Hotspot>();
    public DbSet<Medio> Medios => Set<Medio>();
    public DbSet<Ruta> Rutas => Set<Ruta>();
    public DbSet<RutaPoi> RutaPois => Set<RutaPoi>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Lugar>().HasIndex(x => x.Slug).IsUnique();
        modelBuilder.Entity<Poi>().Property(x => x.Audiencias).HasMaxLength(100);
        modelBuilder.Entity<Poi>()
            .HasOne(x => x.EscenaPrincipal)
            .WithMany()
            .HasForeignKey(x => x.EscenaPrincipalId)
            .OnDelete(DeleteBehavior.SetNull);
        modelBuilder.Entity<Escena>()
            .HasOne(x => x.Poi)
            .WithMany(x => x.Escenas)
            .HasForeignKey(x => x.PoiId)
            .OnDelete(DeleteBehavior.SetNull);
        modelBuilder.Entity<Hotspot>()
            .HasOne(x => x.Escena)
            .WithMany(x => x.Hotspots)
            .HasForeignKey(x => x.EscenaId)
            .OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<Hotspot>()
            .HasOne(x => x.EscenaDestino)
            .WithMany()
            .HasForeignKey(x => x.EscenaDestinoId)
            .OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Hotspot>()
            .HasOne(x => x.Poi)
            .WithMany()
            .HasForeignKey(x => x.PoiId)
            .OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<RutaPoi>().HasKey(x => new { x.RutaId, x.PoiId });
        modelBuilder.Entity<RutaPoi>()
            .HasOne(x => x.Ruta)
            .WithMany(x => x.Pois)
            .HasForeignKey(x => x.RutaId)
            .OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<RutaPoi>()
            .HasOne(x => x.Poi)
            .WithMany()
            .HasForeignKey(x => x.PoiId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
