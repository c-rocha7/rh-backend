import { Module } from '@nestjs/common';
import { Colaborador } from './colaborador/entities/colaborador.entity';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ColaboradorModule } from './colaborador/colaborador.module';
import { Cargo } from './cargo/entities/cargo.entity';
import { CargoModule } from './cargo/cargo.module';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: process.env.DB_HOST ?? 'localhost',
      port: Number(process.env.DB_PORT ?? 3306),
      username: process.env.DB_USER ?? 'root',
      password: process.env.DB_PASSWORD ?? 'root',
      database: process.env.DB_NAME ?? 'db_rhcolaboradores',
      entities: [Colaborador, Cargo],
      synchronize: true,
    }),
    ColaboradorModule,
    CargoModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
