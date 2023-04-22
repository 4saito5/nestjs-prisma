import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { User, Prisma } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async user(
    id: number,
  ): Promise<User | null> {
    // return this.prisma.user.findUnique({
    //   where: { id }
    // });

    return this.prisma.$queryRaw`
      SELECT * FROM "User" WHERE id = ${id}
    `;
  }

  async users(): Promise<User[]> {
    return this.prisma.user.findMany();
  }

  async createUser(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({
      data,
    });
  }
}
