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

    // Tablas de Supabase: existen fuera de las migraciones de EF.
    public DbSet<Evento> Eventos => Set<Evento>();
    public DbSet<RegistroAuditoria> Auditoria => Set<RegistroAuditoria>();
    public DbSet<UsuarioAuth> UsuariosAuth => Set<UsuarioAuth>();

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

        ConfigurarTablasSupabase(modelBuilder);
    }

    /// <summary>
    /// eventos, auditoria y auth.users los crea Supabase
    /// (scripts/datos/perfiles_eventos_auditoria.sql). ExcludeFromMigrations
    /// hace que EF las pueda leer pero nunca intente crearlas ni cambiarlas.
    /// perfiles no se mapea: su columna rol es un enum de Postgres y se lee
    /// con SQL directo en PanelService.
    /// </summary>
    private static void ConfigurarTablasSupabase(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Evento>(e =>
        {
            e.ToTable("eventos", "public", t => t.ExcludeFromMigrations());
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").ValueGeneratedOnAdd();
            e.Property(x => x.SesionId).HasColumnName("sesion_id");
            e.Property(x => x.UserId).HasColumnName("user_id");
            e.Property(x => x.Tipo).HasColumnName("tipo");
            e.Property(x => x.PoiId).HasColumnName("poi_id");
            e.Property(x => x.EscenaId).HasColumnName("escena_id");
            e.Property(x => x.Payload).HasColumnName("payload").HasColumnType("jsonb");
            e.Property(x => x.Ts).HasColumnName("ts");
        });

        modelBuilder.Entity<RegistroAuditoria>(e =>
        {
            e.ToTable("auditoria", "public", t => t.ExcludeFromMigrations());
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id").ValueGeneratedOnAdd();
            e.Property(x => x.ActorId).HasColumnName("actor_id");
            e.Property(x => x.Accion).HasColumnName("accion");
            e.Property(x => x.Entidad).HasColumnName("entidad");
            e.Property(x => x.EntidadId).HasColumnName("entidad_id");
            e.Property(x => x.Antes).HasColumnName("antes").HasColumnType("jsonb");
            e.Property(x => x.Despues).HasColumnName("despues").HasColumnType("jsonb");
            e.Property(x => x.Ts).HasColumnName("ts");
        });

        modelBuilder.Entity<UsuarioAuth>(e =>
        {
            e.ToTable("users", "auth", t => t.ExcludeFromMigrations());
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).HasColumnName("id");
            e.Property(x => x.Email).HasColumnName("email");
        });
    }
}
