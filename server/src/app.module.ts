import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { GameModule } from './game/game.module';
import { User } from './auth/user.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL || 'postgresql://rami:rami@localhost:5432/rami',
      entities: [User],
      synchronize: true, // dev only — use migrations in production
      logging: false,
    }),
    AuthModule,
    GameModule,
  ],
})
export class AppModule {}

