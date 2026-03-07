import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ nullable: true, unique: true })
  email?: string;

  @Column({ nullable: true })
  passwordHash?: string;

  @Column()
  displayName!: string;

  @Column({ default: false })
  isGuest!: boolean;

  @Column({ default: 0 })
  gamesPlayed!: number;

  @Column({ default: 0 })
  gamesWon!: number;

  @CreateDateColumn()
  createdAt!: Date;
}

