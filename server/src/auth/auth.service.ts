import { Injectable, ConflictException, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { v4 as uuid } from 'uuid';
import { User } from './user.entity';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async register(email: string, password: string, displayName: string) {
    const existing = await this.userRepo.findOne({ where: { email } });
    if (existing) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(password, 10);
    const user = this.userRepo.create({ email, passwordHash, displayName, isGuest: false });
    await this.userRepo.save(user);

    return this.issueToken(user);
  }

  async login(email: string, password: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    return this.issueToken(user);
  }

  async guestLogin(displayName?: string) {
    const name = displayName || `Guest_${uuid().slice(0, 6)}`;
    const user = this.userRepo.create({ displayName: name, isGuest: true });
    await this.userRepo.save(user);
    return this.issueToken(user);
  }

  async findById(id: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { id } });
  }

  private issueToken(user: User) {
    const payload = { sub: user.id, name: user.displayName };
    return {
      token: this.jwtService.sign(payload),
      user: { id: user.id, displayName: user.displayName, isGuest: user.isGuest },
    };
  }
}

